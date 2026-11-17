import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/mesh/mesh_identity.dart';
import 'package:tune/data/services/mesh/mesh_messages.dart';
import 'package:tune/features/share/domain/share_ai_disclosure.dart';
import 'package:tune/features/share/domain/share_item.dart';
import 'package:tune/features/share/domain/share_provenance.dart';

ShareItem _item({String name = '夜航'}) {
  return ShareItem(
    contentId: 'a' * 64,
    name: name,
    artist: '本机',
    sizeBytes: 1024,
    provenance: ShareProvenance.generated,
    createdAt: DateTime.utc(2026, 11, 16, 12),
    aiDisclosure: const ShareAiDisclosure(
      isSynthetic: true,
      providerName: 'Tune 本地生成',
      contentNumber: 'tune-0001',
    ),
  );
}

void main() {
  test('身份号由公钥推出，签名能验回来', () async {
    final identity = await MeshIdentity.generate();
    expect(identity.peerId, MeshIdentity.peerIdOf(identity.publicKeyBase64));
    expect(identity.peerId, hasLength(32));

    final payload = Uint8List.fromList([1, 2, 3, 4]);
    final signature = await identity.signBytes(payload);
    expect(
      await MeshIdentity.verifyBytes(
        payload,
        publicKeyBase64: identity.publicKeyBase64,
        signatureBase64: signature,
      ),
      isTrue,
    );
    expect(
      await MeshIdentity.verifyBytes(
        Uint8List.fromList([1, 2, 3, 5]),
        publicKeyBase64: identity.publicKeyBase64,
        signatureBase64: signature,
      ),
      isFalse,
    );
  });

  test('篡改过的公钥或签名一律不通过', () async {
    final identity = await MeshIdentity.generate();
    final payload = Uint8List.fromList([9, 9, 9]);
    final signature = await identity.signBytes(payload);

    expect(
      await MeshIdentity.verifyBytes(
        payload,
        publicKeyBase64: 'not-base64',
        signatureBase64: signature,
      ),
      isFalse,
    );
    expect(
      await MeshIdentity.verifyBytes(
        payload,
        publicKeyBase64: identity.publicKeyBase64,
        signatureBase64: 'AAAA',
      ),
      isFalse,
    );

    final other = await MeshIdentity.generate();
    expect(
      await MeshIdentity.verifyBytes(
        payload,
        publicKeyBase64: other.publicKeyBase64,
        signatureBase64: signature,
      ),
      isFalse,
    );
  });

  test('身份能从磁盘读回来，读不回来就重新生成', () async {
    final dir = await Directory.systemTemp.createTemp('tune-mesh-identity-');
    addTearDown(() async {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });
    final file = File('${dir.path}/identity.json');

    final first = await MeshIdentity.loadOrCreate(file);
    final second = await MeshIdentity.loadOrCreate(file);
    expect(second.peerId, first.peerId);
    expect(second.publicKeyBase64, first.publicKeyBase64);

    await file.writeAsString('不是 json');
    final third = await MeshIdentity.loadOrCreate(file);
    expect(third.peerId, isNot(first.peerId));
  });

  test('清单签名覆盖条目，改一个字段就验不过', () async {
    final identity = await MeshIdentity.generate();
    final manifest = await MeshInventory.sign(
      identity: identity,
      items: [_item()],
    );
    expect(manifest.peerId, identity.peerId);
    expect(await manifest.verify(), isTrue);

    final parsed = MeshInventory.tryFromJson(manifest.toJson());
    expect(parsed, isNotNull);
    expect(await parsed!.verify(), isTrue);

    final tampered = parsed.toJson();
    (tampered['items']! as List<Object?>).first = <String, Object?>{
      ...((tampered['items']! as List<Object?>).first! as Map).cast<String, Object?>(),
      'name': '偷换的名字',
    };
    final after = MeshInventory.tryFromJson(tampered);
    expect(after, isNotNull);
    expect(await after!.verify(), isFalse);
  });

  test('清单里换了别人的身份号也验不过', () async {
    final identity = await MeshIdentity.generate();
    final other = await MeshIdentity.generate();
    final manifest = await MeshInventory.sign(
      identity: identity,
      items: [_item()],
    );
    final hijacked = <String, Object?>{
      ...manifest.toJson(),
      'peerId': other.peerId,
    };
    final parsed = MeshInventory.tryFromJson(hijacked);
    expect(parsed, isNotNull);
    expect(await parsed!.verify(), isFalse);
  });

  test('没签名的清单不算验过', () async {
    final unsigned = MeshInventory(peerId: 'p1', items: [_item()]);
    expect(await unsigned.verify(), isFalse);
    final parsed = MeshInventory.tryFromJson(unsigned.toJson());
    expect(parsed, isNotNull);
    expect(await parsed!.verify(), isFalse);
  });
}
