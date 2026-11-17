import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:xml/xml.dart';

import 'room_invite.dart';

/// 一条「别人可能连得上我」的地址。
enum ReachableKind {
  /// 同网段能连：局域网地址，最稳的那条。
  lan,

  /// 公网 IPv6 直连：没有 NAT，也不需要映射。
  publicV6,

  /// 路由器被自动要到的端口映射（UPnP / NAT-PMP）。
  mappedV4,
}

class ReachableEndpoint {
  const ReachableEndpoint({
    required this.host,
    required this.port,
    required this.kind,
  });

  final String host;
  final int port;
  final ReachableKind kind;

  bool get isPublic => kind != ReachableKind.lan;

  String get seed => RoomInvite.formatSeed(host, port);
}

class ReachabilityReport {
  const ReachabilityReport({required this.endpoints});

  final List<ReachableEndpoint> endpoints;

  bool get hasPublic => endpoints.any((endpoint) => endpoint.isPublic);

  List<String> get seeds => [for (final endpoint in endpoints) endpoint.seed];
}

/// 自动探测房间的可达地址。
///
/// 房间里没有「填地址」的输入框，也没有「一键穿透」的按钮：开房时自己找
/// 本机的局域网地址、公网 IPv6，并试着让路由器把端口自动映射出去
/// （UPnP IGD 或 NAT-PMP）。三条都不成，就只发局域网地址——那说明这条
/// 网络确实没有可直连的入口，而不是等人去配。
///
/// 刻意不做打洞、不做中继、不做会合服务器（`docs/ai-music-sharing.md` §5.6）。
class MeshReachability {
  MeshReachability({
    Future<List<InternetAddress>> Function()? localAddresses,
    Future<String?> Function(int port)? upnp,
    Future<String?> Function(int port)? natPmp,
  })  : _localAddresses = localAddresses ?? _enumerateLocalAddresses,
        _upnp = upnp ?? UpnpPortMapper().mapTcp,
        _natPmp = natPmp ?? NatPmpClient().mapTcp;

  /// 探测多少秒算超时：媒体搜索与路由器握手都不该让人等。
  static const Duration searchTimeout = Duration(seconds: 2);

  final Future<List<InternetAddress>> Function() _localAddresses;
  final Future<String?> Function(int port) _upnp;
  final Future<String?> Function(int port) _natPmp;

  Future<ReachabilityReport> probe({required int port}) async {
    final endpoints = <ReachableEndpoint>[];
    final seen = <String>{};

    void add(String host, ReachableKind kind) {
      if (!RoomInvite.isWellFormedSeed(RoomInvite.formatSeed(host, port))) {
        return;
      }
      if (seen.add('$host:$port')) {
        endpoints.add(ReachableEndpoint(host: host, port: port, kind: kind));
      }
    }

    final addresses = await _safe(_localAddresses) ?? const <InternetAddress>[];
    for (final address in addresses) {
      if (address.isLoopback) {
        continue;
      }
      if (address.type == InternetAddressType.IPv6) {
        if (address.isLinkLocal) {
          continue;
        }
        final isPublicV6 = _isPublicV6(address);
        add(address.address, isPublicV6 ? ReachableKind.publicV6 : ReachableKind.lan);
      } else {
        add(address.address, ReachableKind.lan);
      }
    }

    final external = await _safe(() => _mapPort(port));
    if (external != null) {
      add(external, ReachableKind.mappedV4);
    }

    return ReachabilityReport(endpoints: List.unmodifiable(endpoints));
  }

  /// 先问 UPnP，问不到再问 NAT-PMP：两条都是「让路由器自己开个口」，
  /// 都不需要我们去转发流量。
  Future<String?> _mapPort(int port) async {
    final viaUpnp = await _safe<String?>(() => _upnp(port));
    if (viaUpnp != null) {
      return viaUpnp;
    }
    return _safe<String?>(() => _natPmp(port));
  }

  static bool _isPublicV6(InternetAddress address) {
    final bytes = address.rawAddress;
    if (bytes.length != 16) {
      return false;
    }
    // ULA（fc00::/7）只在自家网络里能用，不算公网直连。
    return (bytes[0] & 0xfe) != 0xfc;
  }

  static Future<T?> _safe<T>(Future<T> Function() action) async {
    try {
      return await action().timeout(searchTimeout);
    } on Object {
      return null;
    }
  }

  static Future<List<InternetAddress>> _enumerateLocalAddresses() async {
    final result = <InternetAddress>[];
    for (final type in const [
      InternetAddressType.IPv4,
      InternetAddressType.IPv6,
    ]) {
      try {
        final interfaces = await NetworkInterface.list(
          type: type,
          includeLoopback: false,
        );
        for (final interface in interfaces) {
          result.addAll(interface.addresses);
        }
      } on SocketException {
        continue;
      }
    }
    return result;
  }
}

/// UPnP IGD：SSDP 找网关 → 读描述 → 加端口映射 → 读公网 IP。
///
/// 全程只说标准协议，不经过任何我们自己的服务器。
class UpnpPortMapper {
  static const String searchTarget =
      'urn:schemas-upnp-org:device:InternetGatewayDevice:1';
  static const String _mSearch = 'M-SEARCH * HTTP/1.1\r\n'
      'HOST: 239.255.255.250:1900\r\n'
      'MAN: "ssdp:discover"\r\n'
      'MX: 1\r\n'
      'ST: $searchTarget\r\n\r\n';

  Future<String?> mapTcp(int port) async {
    final location = await _search();
    if (location == null) {
      return null;
    }
    final description = await _fetch(location);
    if (description == null) {
      return null;
    }
    final control = _findWanControl(description, location);
    if (control == null) {
      return null;
    }
    final local = await _localIpv4();
    if (local == null) {
      return null;
    }
    final added = await _soap(
      control,
      'AddPortMapping',
      '<NewRemoteHost></NewRemoteHost>'
      '<NewExternalPort>$port</NewExternalPort>'
      '<NewProtocol>TCP</NewProtocol>'
      '<NewInternalPort>$port</NewInternalPort>'
      '<NewInternalClient>$local</NewInternalClient>'
      '<NewEnabled>1</NewEnabled>'
      '<NewPortMappingDescription>Tune share</NewPortMappingDescription>'
      '<NewLeaseDuration>0</NewLeaseDuration>',
    );
    if (!added) {
      return null;
    }
    final body = await _soapBody(control, 'GetExternalIPAddress', '');
    return body == null ? null : parseExternalIp(body);
  }

  Future<String?> _search() async {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    final completer = Completer<String?>();
    try {
      socket.broadcastEnabled = true;
      socket.listen((event) {
        if (event != RawSocketEvent.read) {
          return;
        }
        final datagram = socket.receive();
        if (datagram == null) {
          return;
        }
        final value = parseSearchResponse(utf8.decode(datagram.data, allowMalformed: true));
        if (value != null && !completer.isCompleted) {
          completer.complete(value);
        }
      });
      socket.send(
        utf8.encode(_mSearch),
        InternetAddress('239.255.255.250'),
        1900,
      );
      return await completer.future.timeout(
        MeshReachability.searchTimeout,
        onTimeout: () => null,
      );
    } finally {
      socket.close();
    }
  }

  Future<String?> _fetch(String location) async {
    try {
      final client = HttpClient()..connectionTimeout = MeshReachability.searchTimeout;
      try {
        final request = await client.getUrl(Uri.parse(location));
        final response = await request.close();
        if (response.statusCode != 200) {
          return null;
        }
        return await response.transform(utf8.decoder).join();
      } finally {
        client.close(force: true);
      }
    } on Object {
      return null;
    }
  }

  Future<bool> _soap(String controlUrl, String action, String body) async {
    final response = await _soapBody(controlUrl, action, body);
    return response != null;
  }

  Future<String?> _soapBody(String controlUrl, String action, String body) async {
    final service = 'urn:schemas-upnp-org:service:WANIPConnection:1';
    final payload = '<?xml version="1.0"?>'
        '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" '
        's:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">'
        '<s:Body><u:$action xmlns:u="$service">$body</u:$action></s:Body>'
        '</s:Envelope>';
    try {
      final client = HttpClient()..connectionTimeout = MeshReachability.searchTimeout;
      try {
        final request = await client.postUrl(Uri.parse(controlUrl));
        request.headers.set(
          'SOAPAction',
          '"$service#$action"',
        );
        request.headers.contentType =
            ContentType('text', 'xml', charset: 'utf-8');
        request.write(payload);
        final response = await request.close();
        if (response.statusCode != 200) {
          return null;
        }
        return await response.transform(utf8.decoder).join();
      } finally {
        client.close(force: true);
      }
    } on Object {
      return null;
    }
  }

  /// 从设备描述里挑出 WANIPConnection（或 WANPPPConnection）的 controlURL，
  /// 相对地址按 LOCATION 的根拼回绝对地址。
  String? _findWanControl(String description, String location) {
    final doc = tryParseXml(description);
    if (doc == null) {
      return null;
    }
    for (final service in doc.findAllElements('service')) {
      final type = service.findElements('serviceType').firstOrNull?.innerText ?? '';
      final control = service.findElements('controlURL').firstOrNull?.innerText ?? '';
      if (control.isEmpty) {
        continue;
      }
      if (type.contains('WANIPConnection') || type.contains('WANPPPConnection')) {
        return resolveUrl(location, control);
      }
    }
    return null;
  }

  static Future<String?> _localIpv4() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (!address.isLoopback && address.type == InternetAddressType.IPv4) {
            return address.address;
          }
        }
      }
    } on SocketException {
      return null;
    }
    return null;
  }

  /// SSDP 回应里只关心 `LOCATION`。
  static String? parseSearchResponse(String text) {
    for (final line in text.split('\r\n')) {
      final index = line.indexOf(':');
      if (index <= 0) {
        continue;
      }
      if (line.substring(0, index).trim().toLowerCase() == 'location') {
        final value = line.substring(index + 1).trim();
        return value.isEmpty ? null : value;
      }
    }
    return null;
  }

  static String resolveUrl(String base, String relative) {
    if (relative.startsWith('http://') || relative.startsWith('https://')) {
      return relative;
    }
    final resolved = Uri.parse(base).resolve(relative);
    return resolved.toString();
  }

  /// `GetExternalIPAddress` 的响应体里取公网 IPv4；拿到 0.0.0.0 当没有。
  static String? parseExternalIp(String soapBody) {
    final match = RegExp(r'<NewExternalIPAddress>([^<]+)<').firstMatch(soapBody);
    final value = match?.group(1)?.trim();
    if (value == null || value.isEmpty || value == '0.0.0.0') {
      return null;
    }
    return InternetAddress.tryParse(value) == null ? null : value;
  }

  static XmlDocument? tryParseXml(String body) {
    try {
      return XmlDocument.parse(body);
    } on XmlException {
      return null;
    }
  }
}

/// NAT-PMP（RFC 6886）：直接问网关要一个 TCP 映射。
///
/// 网关地址从 `/proc/net/route` 读（Linux），读不到就放弃——本项目验收平台
/// 就是 Linux，别的平台走 UPnP 那条。
class NatPmpClient {
  static const int port = 5351;

  Future<String?> mapTcp(int port) async {
    final gateway = InternetAddress.tryParse(readGateway() ?? '');
    if (gateway == null) {
      return null;
    }
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    try {
      final external = await _request(
        socket,
        gateway,
        buildExternalAddressRequest(),
      );
      if (external == null) {
        return null;
      }
      final mapped = await _request(
        socket,
        gateway,
        buildMapRequest(tcpPort: port, lifetimeSeconds: 3600),
      );
      if (mapped == null) {
        return null;
      }
      final ip = parseExternalAddressResponse(external);
      if (ip == null || ip == '0.0.0.0') {
        return null;
      }
      return ip;
    } finally {
      socket.close();
    }
  }

  Future<List<int>?> _request(
    RawDatagramSocket socket,
    InternetAddress gateway,
    List<int> payload,
  ) async {
    final completer = Completer<List<int>?>();
    final subscription = socket.listen((event) {
      if (event != RawSocketEvent.read) {
        return;
      }
      final datagram = socket.receive();
      if (datagram != null && !completer.isCompleted) {
        completer.complete(datagram.data);
      }
    });
    try {
      socket.send(payload, gateway, port);
      return await completer.future.timeout(
        MeshReachability.searchTimeout,
        onTimeout: () => null,
      );
    } finally {
      await subscription.cancel();
    }
  }

  /// 网关地址：`/proc/net/route` 里 Destination 为 0 的那行。
  static String? readGateway({String? routeFile}) {
    final path = routeFile ?? '/proc/net/route';
    final file = File(path);
    final text = file.existsSync() ? file.readAsStringSync() : '';
    if (text.isEmpty) {
      return null;
    }
    for (final line in text.split('\n')) {
      final fields = line.split('\t');
      if (fields.length < 3 || fields[1] != '00000000') {
        continue;
      }
      final gateway = int.tryParse(fields[2], radix: 16);
      if (gateway == null) {
        continue;
      }
      return '${gateway & 0xff}.${(gateway >> 8) & 0xff}'
          '.${(gateway >> 16) & 0xff}.${(gateway >> 24) & 0xff}';
    }
    return null;
  }

  static List<int> buildExternalAddressRequest() => <int>[0, 0];

  static List<int> buildMapRequest({
    required int tcpPort,
    required int lifetimeSeconds,
  }) =>
      <int>[
        0,
        2,
        0,
        0,
        (tcpPort >> 8) & 0xff,
        tcpPort & 0xff,
        (tcpPort >> 8) & 0xff,
        tcpPort & 0xff,
        (lifetimeSeconds >> 24) & 0xff,
        (lifetimeSeconds >> 16) & 0xff,
        (lifetimeSeconds >> 8) & 0xff,
        lifetimeSeconds & 0xff,
      ];

  /// 公网地址响应：版本(0) 操作码(128) 结果码 时间戳(4) IP(4)。
  static String? parseExternalAddressResponse(List<int> data) {
    if (data.length < 12 || data[1] != 128 || data[2] != 0) {
      return null;
    }
    return '${data[8]}.${data[9]}.${data[10]}.${data[11]}';
  }
}
