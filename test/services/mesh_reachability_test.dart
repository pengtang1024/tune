import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/mesh/mesh_reachability.dart';

void main() {
  group('SSDP 与 SOAP 的解析', () {
    test('从回应里取 LOCATION，大小写不敏感', () {
      const response = 'HTTP/1.1 200 OK\r\n'
          'CACHE-CONTROL: max-age=120\r\n'
          'location: http://192.168.1.1:49152/rootDesc.xml\r\n'
          '\r\n';
      expect(
        UpnpPortMapper.parseSearchResponse(response),
        'http://192.168.1.1:49152/rootDesc.xml',
      );
      expect(UpnpPortMapper.parseSearchResponse('HTTP/1.1 200 OK\r\n\r\n'), isNull);
    });

    test('controlURL 是相对地址时按描述文件的位置拼绝对地址', () {
      expect(
        UpnpPortMapper.resolveUrl(
          'http://192.168.1.1:49152/rootDesc.xml',
          '/ctl/IPConn',
        ),
        'http://192.168.1.1:49152/ctl/IPConn',
      );
      expect(
        UpnpPortMapper.resolveUrl('http://gw:80/a/b.xml', 'http://other:9/x'),
        'http://other:9/x',
      );
    });

    test('公网 IP 只认真的地址，0.0.0.0 当没有', () {
      expect(
        UpnpPortMapper.parseExternalIp(
          '<NewExternalIPAddress>203.0.113.7</NewExternalIPAddress>',
        ),
        '203.0.113.7',
      );
      expect(
        UpnpPortMapper.parseExternalIp(
          '<NewExternalIPAddress>0.0.0.0</NewExternalIPAddress>',
        ),
        isNull,
      );
      expect(
        UpnpPortMapper.parseExternalIp('<NewExternalIPAddress>nope</NewExternalIPAddress>'),
        isNull,
      );
    });
  });

  group('NAT-PMP', () {
    test('映射请求按 RFC 6886 摆字节：TCP、内外同端口、寿命 3600', () {
      final request = NatPmpClient.buildMapRequest(tcpPort: 45871, lifetimeSeconds: 3600);
      expect(request.sublist(0, 2), [0, 2]);
      expect(request.sublist(4, 6), [45871 >> 8, 45871 & 0xff]);
      expect(request.sublist(6, 8), [45871 >> 8, 45871 & 0xff]);
      expect(request.sublist(8, 12), [0, 0, 0x0e, 0x10]);
    });

    test('公网地址响应取最后四个字节，错误码当没有', () {
      expect(
        NatPmpClient.parseExternalAddressResponse(
          [0, 128, 0, 0, 0, 0, 0, 0, 203, 0, 113, 7],
        ),
        '203.0.113.7',
      );
      expect(
        NatPmpClient.parseExternalAddressResponse(
          [0, 128, 1, 0, 0, 0, 0, 0, 203, 0, 113, 7],
        ),
        isNull,
      );
    });

    test('网关从 /proc/net/route 的默认路由那行读出来', () async {
      final file = File('${Directory.systemTemp.createTempSync('route-').path}/route');
      await file.writeAsString(
        'Iface\tDestination\tGateway \tFlags\tRefCnt\tUse\tMetric\tMask\t\tMTU\tWindow\tIRTT\n'
        'eth0\t00000000\t0102A8C0\t0003\t0\t0\t0\t00000000\t0\t0\t0\n',
      );
      expect(NatPmpClient.readGateway(routeFile: file.path), '192.168.2.1');
      expect(NatPmpClient.readGateway(routeFile: '/nonexistent/route'), isNull);
    });
  });

  group('探测结果', () {
    test('局域网、公网 IPv6、路由器映射各一条，链路本地地址不算', () async {
      final report = await MeshReachability(
        localAddresses: () async => [
          InternetAddress('192.168.1.9'),
          InternetAddress('fe80::1'),
          InternetAddress('2001:db8::7'),
          InternetAddress('192.168.1.9'),
        ],
        upnp: (_) async => '203.0.113.7',
        natPmp: (_) async => null,
      ).probe(port: 45871);

      expect(
        report.seeds,
        ['192.168.1.9:45871', '[2001:db8::7]:45871', '203.0.113.7:45871'],
      );
      expect(report.hasPublic, isTrue);
      expect(report.endpoints.last.kind, ReachableKind.mappedV4);
    });

    test('都探不到时只发局域网，并明确不是公网可达', () async {
      final report = await MeshReachability(
        localAddresses: () async => [InternetAddress('10.0.0.5')],
        upnp: (_) async => null,
        natPmp: (_) async => null,
      ).probe(port: 1234);

      expect(report.seeds, ['10.0.0.5:1234']);
      expect(report.hasPublic, isFalse);
    });

    test('UPnP 超时不影响后续，仍然给出局域网地址', () async {
      final report = await MeshReachability(
        localAddresses: () async => [InternetAddress('10.0.0.5')],
        upnp: (_) => Future<String?>.delayed(
          const Duration(seconds: 30),
          () => '203.0.113.9',
        ),
        natPmp: (_) async => null,
      ).probe(port: 4321);

      expect(report.seeds, ['10.0.0.5:4321']);
    });
  });
}
