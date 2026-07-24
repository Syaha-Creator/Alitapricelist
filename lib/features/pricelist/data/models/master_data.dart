import 'package:freezed_annotation/freezed_annotation.dart';

part 'master_data.freezed.dart';

/// `pl_areas` / `pl_channels` / `pl_brands` have no documented response
/// contract in the legacy app either — it reads raw maps ad hoc. These
/// models exist so nothing downstream has to touch a raw `Map` (SPEC.md §6),
/// but every field still degrades to a default instead of throwing when the
/// server's actual shape doesn't match what we've observed.
@freezed
class Area with _$Area {
  const factory Area({@Default('') String name}) = _Area;

  factory Area.fromJson(Map<String, dynamic> json) {
    return Area(name: json['name']?.toString() ?? json['area']?.toString() ?? '');
  }
}

@freezed
class Channel with _$Channel {
  const factory Channel({@Default(0) int id, @Default('') String channel}) = _Channel;

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(id: _parseInt(json['id']), channel: json['channel']?.toString() ?? '');
  }
}

/// `plChannelId` is how brands are filtered down to the ones that belong to
/// the currently-selected channel (client-side join — the API itself has no
/// "brands for this channel" endpoint).
@freezed
class Brand with _$Brand {
  const factory Brand({
    @Default(0) int id,
    @Default('') String brand,
    @Default(0) int plChannelId,
  }) = _Brand;

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: _parseInt(json['id']),
      brand: json['brand']?.toString() ?? '',
      plChannelId: _parseInt(json['pl_channel_id']),
    );
  }
}

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

/// `pl_areas`/`pl_channels`/`pl_brands` have been observed returning several
/// different envelope shapes in the wild (bare list, `{"data": [...]}`,
/// `{"<listKey>": [...]}`, or any of those nested one level under
/// `"result"`). This tolerates all of them instead of assuming one specific
/// shape and crashing on the others — entries that aren't maps are dropped
/// rather than causing a cast failure.
List<Map<String, dynamic>> parseMasterDataEnvelope(dynamic decoded, {required String listKey}) {
  if (decoded is List) {
    return decoded.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }
  if (decoded is Map) {
    final data = decoded['data'] ?? decoded[listKey];
    if (data != null) {
      return parseMasterDataEnvelope(data, listKey: listKey);
    }
    final result = decoded['result'];
    if (result != null) {
      return parseMasterDataEnvelope(result, listKey: listKey);
    }
  }
  return const [];
}
