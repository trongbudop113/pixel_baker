import '../models/voucher_models.dart';
import '../network/api_exception.dart';
import '../network/base_api_repository.dart';
import '../services/auth_session.dart';

abstract class VoucherRepository {
  Future<List<VoucherModel>> fetchVouchers();
  Future<String> collectVoucher(String code);
  Future<VoucherValidationResult> validateVoucher({
    required String code,
    required int subtotal,
    required int deliveryFee,
    String? customerUserId,
  });
}

class ApiVoucherRepository extends BaseApiRepository implements VoucherRepository {
  ApiVoucherRepository(super.apiClient, this._authSession);

  final AuthSession _authSession;

  @override
  Future<List<VoucherModel>> fetchVouchers() async {
    final response = await apiClient.get<List<VoucherModel>>(
      '/voucher',
      requiresAuth: _authSession.isAuthenticated,
      decoder: (json) {
        final payload = _unwrapItemPayload(json);
        return readList(payload, VoucherModel.fromJson);
      },
    );
    return response.data;
  }

  @override
  Future<String> collectVoucher(String code) async {
    final response = await apiClient.post<String>(
      '/voucher/collect/$code',
      requiresAuth: true,
      decoder: (json) {
        final payload = _unwrapMessagePayload(json);
        if (payload is Map<String, dynamic>) {
          return (payload['message'] ?? 'Thu thập voucher thành công.')
              .toString();
        }
        return 'Thu thập voucher thành công.';
      },
    );
    return response.data;
  }

  @override
  Future<VoucherValidationResult> validateVoucher({
    required String code,
    required int subtotal,
    required int deliveryFee,
    String? customerUserId,
  }) async {
    final response = await apiClient.post<VoucherValidationResult>(
      '/voucher/validate',
      requiresAuth: true,
      body: {
        'code': code,
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'customerUserId': customerUserId,
      },
      decoder: (json) => readItem(
        _unwrapMessagePayload(json),
        VoucherValidationResult.fromJson,
      ),
    );
    return response.data;
  }

  Object? _unwrapItemPayload(Object? json) {
    if (json is Map<String, dynamic>) {
      return json['items'] ?? json['data'] ?? json['item'] ?? json;
    }
    return json;
  }

  Object? _unwrapMessagePayload(Object? json) {
    if (json is Map<String, dynamic>) {
      return json['data'] ?? json['item'] ?? json;
    }
    throw const ApiException(
      message: 'Invalid voucher response payload',
      code: 'invalid_voucher_payload',
    );
  }
}
