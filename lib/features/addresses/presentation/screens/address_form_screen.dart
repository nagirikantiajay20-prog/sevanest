import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/core/services/location_service.dart';
import 'package:sevanest_customer/core/widgets/async_value_view.dart';
import 'package:sevanest_customer/core/widgets/labeled_field.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/core/widgets/sn_states.dart';
import 'package:sevanest_customer/features/addresses/domain/address.dart';
import 'package:sevanest_customer/features/addresses/presentation/providers/address_providers.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';
import 'package:sevanest_customer/shared/utils/validators.dart';

/// `/addresses/new` and `/addresses/:id/edit` (modules/02, screen 2.2).
/// [firstTime] = reached right after profile setup: Skip is offered and Save continues to Home.
class AddressFormScreen extends ConsumerWidget {
  const AddressFormScreen({
    this.addressId,
    this.firstTime = false,
    this.prefill,
    super.key,
  });

  /// Area / city / pincode found from the device location (discovery step 3).
  final AddressInput? prefill;

  final String? addressId;
  final bool firstTime;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final id = addressId;
    final title = Text(id == null ? l10n.addAddress : l10n.editAddressTitle);
    if (id == null) {
      return Scaffold(
        appBar: AppBar(title: title),
        body: _AddressForm(firstTime: firstTime, prefill: prefill),
      );
    }
    final list = ref.watch(addressesProvider);
    return Scaffold(
      appBar: AppBar(title: title),
      body: AsyncValueView<List<Address>>(
        value: list,
        onRetry: () => ref.invalidate(addressesProvider),
        data: (all) {
          final match = all.where((a) => a.id == id);
          if (match.isEmpty) {
            return SnErrorState(message: l10n.addressNotFound);
          }
          return _AddressForm(initial: match.first, firstTime: firstTime);
        },
      ),
    );
  }
}

/// The add-address bottom sheet of design screen 08 (same form as `/addresses/new`). Resolves to
/// the saved [Address], or null when closed.
Future<Address?> showAddAddressSheet(
  BuildContext context, {
  AddressInput? prefill,
}) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<Address>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(ctx).height * 0.9,
        child: Column(
          children: [
            ListTile(
              title: Text(
                l10n.addAddress,
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              trailing: IconButton(
                key: const Key('address_sheet_close_btn'),
                tooltip: MaterialLocalizations.of(ctx).closeButtonLabel,
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(ctx).maybePop(),
              ),
            ),
            Expanded(
              child: _AddressForm(
                firstTime: false,
                prefill: prefill,
                inSheet: true,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AddressForm extends ConsumerStatefulWidget {
  const _AddressForm({
    required this.firstTime,
    this.initial,
    this.prefill,
    this.inSheet = false,
  });
  final bool inSheet;
  final AddressInput? prefill;
  final Address? initial;
  final bool firstTime;

  @override
  ConsumerState<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends ConsumerState<_AddressForm> {
  late final _label = TextEditingController(text: widget.initial?.label ?? '');
  late final _house = TextEditingController(text: _parts(widget.initial).$1);
  late final _street = TextEditingController(text: _parts(widget.initial).$2);
  late final _area = TextEditingController(
    text: widget.initial?.area ?? widget.prefill?.area ?? '',
  );
  late final _city = TextEditingController(
    text: widget.initial?.city ?? widget.prefill?.city ?? defaultCity,
  );
  late final _pincode = TextEditingController(
    text: widget.initial?.pincode ?? widget.prefill?.pincode ?? '',
  );
  late bool _default = widget.initial?.isDefault ?? false;
  late double? _lat = widget.prefill?.latitude;
  late double? _lng = widget.prefill?.longitude;
  bool _locating = false;
  bool _locationOff = false;
  bool _defaultTouched = false;

  Address? get _initial => widget.initial;
  bool get _isEdit => _initial != null;

  /// House and street: `line` and `line2`. An address saved before `line2` existed kept both in
  /// `line` as "house, street".
  static (String, String) _parts(Address? a) {
    if (a == null) return ('', '');
    final line2 = a.line2;
    if (line2 != null && line2.isNotEmpty) return (a.line, line2);
    final i = a.line.indexOf(', ');
    return i < 0
        ? (a.line, '')
        : (a.line.substring(0, i), a.line.substring(i + 2));
  }

  @override
  void initState() {
    super.initState();
    // First address ever: pre-select "default" (user can still switch it off).
    if (!_isEdit) {
      ref.read(addressesProvider.future).then((list) {
        if (mounted && list.isEmpty && !_defaultTouched) {
          setState(() => _default = true);
        }
      }, onError: (_) {});
    }
  }

  @override
  void dispose() {
    for (final c in [_label, _house, _street, _area, _city, _pincode]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _dirty {
    final a = _initial;
    if (a == null) {
      return [
            _label,
            _house,
            _street,
            _area,
            _pincode,
          ].any((c) => c.text.isNotEmpty) ||
          _city.text != defaultCity ||
          _defaultTouched;
    }
    final (house, street) = _parts(a);
    return _house.text.trim() != house ||
        _street.text.trim() != street ||
        _label.text.trim() != (a.label ?? '') ||
        _area.text.trim() != a.area ||
        _city.text.trim() != a.city ||
        _pincode.text.trim() != a.pincode ||
        _default != a.isDefault;
  }

  bool get _valid =>
      _house.text.trim().isNotEmpty &&
      _street.text.trim().isNotEmpty &&
      _area.text.trim().isNotEmpty &&
      _city.text.trim().isNotEmpty &&
      isValidPincode(_pincode.text);

  void _leave() => widget.inSheet
      ? Navigator.of(context).pop()
      : context.canPop()
      ? context.pop()
      : context.go(Routes.home);

  Future<void> _confirmLeave() async {
    final l10n = AppLocalizations.of(context);
    final discard = await confirmDialog(
      context,
      title: l10n.discardTitle,
      body: l10n.discardBody,
      confirmLabel: l10n.discard,
      cancelLabel: l10n.keepEditing,
      confirmKey: const Key('address_discard_confirm_btn'),
    );
    if (discard && mounted) _leave();
  }

  /// Fills area / city / pincode (and keeps the coordinates) from the device location. House and
  /// street stay for the customer; an area the service-area list doesn't know is left to pick.
  Future<void> _useCurrentLocation() async {
    if (_locating) return;
    setState(() {
      _locating = true;
      _locationOff = false;
    });
    final res = await ref.read(locationServiceProvider).currentAddress();
    if (!mounted) return;
    setState(() => _locating = false);
    final found = res.input;
    if (res.outcome != LocationOutcome.found || found == null) {
      setState(() => _locationOff = true);
      return;
    }
    final known = ref.read(serviceAreasProvider).asData?.value ?? const [];
    final match = known
        .where((a) => a.name.toLowerCase() == found.area.toLowerCase())
        .firstOrNull;
    // The backend knows the circle of each area: ask it before leaving the customer to pick.
    final resolved = match ?? await resolveFoundArea(ref, found);
    if (!mounted) return;
    setState(() {
      _area.text = known.isEmpty && resolved == null
          ? found.area
          : (resolved?.name ?? '');
      final city = resolved?.city ?? found.city;
      if (city.isNotEmpty) _city.text = city;
      _pincode.text = found.pincode;
      _lat = found.latitude;
      _lng = found.longitude;
    });
  }

  Future<void> _save() async {
    if (!_valid) return;
    final messenger = ScaffoldMessenger.of(context);
    final savedText = AppLocalizations.of(context).addressSaved;
    final saved = await ref
        .read(addressFormProvider.notifier)
        .save(
          id: _initial?.id,
          makeDefault: _isEdit && _default && !_initial!.isDefault,
          input: AddressInput(
            line: _house.text.trim(),
            line2: _street.text.trim(),
            label: _label.text,
            state: _initial?.state,
            area: _area.text,
            city: _city.text,
            pincode: _pincode.text,
            isDefault: _default,
            latitude: _lat,
            longitude: _lng,
          ),
        );
    if (saved == null || !mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(savedText)));
    if (widget.inSheet) {
      Navigator.of(context).pop(saved);
    } else if (widget.firstTime) {
      context.go(Routes.home);
    } else if (context.canPop()) {
      context.pop(saved);
    } else {
      context.go(Routes.home);
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final yes = await confirmDialog(
      context,
      title: l10n.deleteConfirmTitle,
      body: l10n.deleteConfirmBody,
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
      confirmKey: const Key('address_delete_confirm_btn'),
      destructive: true,
    );
    if (!yes || !mounted) return;
    final ok = await ref
        .read(addressFormProvider.notifier)
        .delete(_initial!.id);
    if (!mounted) return;
    if (ok) {
      _leave();
    } else if (ref.read(addressFormProvider).failure is ConflictFailure) {
      await infoDialog(
        context,
        body: l10n.addressInUse,
        okLabel: MaterialLocalizations.of(context).okButtonLabel,
      );
    }
  }

  Future<void> _pickArea(List<ServiceArea> areas) async {
    final l10n = AppLocalizations.of(context);
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              l10n.chooseArea,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final a in areas)
                  ListTile(
                    key: Key('area_option_${a.name}'),
                    title: Text(a.name),
                    trailing: a.name == _area.text.trim()
                        ? const Icon(Icons.check, color: AppColors.teal)
                        : null,
                    onTap: () => Navigator.of(ctx).pop(a.name),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (picked != null) setState(() => _area.text = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final form = ref.watch(addressFormProvider);
    final failure = form.failure;
    final fieldErrors = failure is ValidationFailure
        ? failure.fieldErrors
        : const <String, String>{};
    final general =
        failure != null &&
            !(failure is ValidationFailure && fieldErrors.isNotEmpty) &&
            failure is! ConflictFailure
        ? failureMessage(l10n, failure)
        // Conflict on save (not delete) is a business rule: show the backend's message.
        : failure is ConflictFailure && failure.message != null
        ? failure.message
        : null;
    final areas = ref.watch(serviceAreasProvider);
    final areaList = areas.asData?.value ?? const <ServiceArea>[];
    final picker = areaList.isNotEmpty;
    final pincodeBad =
        _pincode.text.isNotEmpty && !isValidPincode(_pincode.text);

    return PopScope(
      canPop: !_dirty || form.busy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isEdit) ...[
                    OutlinedButton.icon(
                      key: const Key('address_use_location_btn'),
                      onPressed: form.busy || _locating
                          ? null
                          : _useCurrentLocation,
                      icon: _locating
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                      label: Text(l10n.locationUseCurrent),
                    ),
                    if (_locationOff)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Text(
                          l10n.addressLocationFailed,
                          key: const Key('address_location_error'),
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  LabeledField(
                    name: 'address_label_field',
                    label: l10n.addressLabelLabel,
                    hint: l10n.addressLabelHint,
                    controller: _label,
                    enabled: !form.busy,
                    maxLength: 40,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  LabeledField(
                    name: 'address_line1_field',
                    label: l10n.houseLabel,
                    hint: l10n.houseHint,
                    controller: _house,
                    enabled: !form.busy,
                    textInputAction: TextInputAction.next,
                    error: fieldErrors['line'],
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  LabeledField(
                    name: 'address_line2_field',
                    label: l10n.streetLabel,
                    hint: l10n.streetHint,
                    controller: _street,
                    enabled: !form.busy,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  LabeledField(
                    name: 'address_area_field',
                    label: l10n.areaLabel,
                    hint: l10n.areaHint,
                    controller: _area,
                    enabled: !form.busy,
                    readOnly: picker,
                    onTap: picker ? () => _pickArea(areaList) : null,
                    suffixIcon: picker
                        ? const Icon(Icons.expand_more_rounded)
                        : null,
                    helper: areas.hasError ? l10n.areasUnavailable : null,
                    error: fieldErrors['area'],
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  LabeledField(
                    name: 'address_city_field',
                    label: l10n.cityLabel,
                    controller: _city,
                    enabled: !form.busy,
                    textInputAction: TextInputAction.next,
                    error: fieldErrors['city'],
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  LabeledField(
                    name: 'address_pincode_field',
                    label: l10n.pincodeLabel,
                    hint: l10n.pincodeHint,
                    controller: _pincode,
                    enabled: !form.busy,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    error: pincodeBad
                        ? l10n.pincodeInvalid
                        : fieldErrors['pincode'],
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SwitchListTile(
                    key: const Key('address_default_switch'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.setAsDefault),
                    subtitle: _initial?.isDefault ?? false
                        ? Text(l10n.alreadyDefault)
                        : null,
                    value: _default,
                    // The API can't unset a default: another address must be made default instead.
                    onChanged: form.busy || (_initial?.isDefault ?? false)
                        ? null
                        : (v) => setState(() {
                            _default = v;
                            _defaultTouched = true;
                          }),
                  ),
                  if (general != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    FormErrorBanner(
                      general,
                      key: const Key('address_error_banner'),
                    ),
                  ],
                  if (_isEdit) ...[
                    const SizedBox(height: AppSpacing.md),
                    TextButton.icon(
                      key: const Key('address_delete_btn'),
                      onPressed: form.busy ? null : _delete,
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.danger,
                      ),
                      label: Text(
                        l10n.deleteAddress,
                        style: const TextStyle(color: AppColors.danger),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SnButton(
                    key: const Key('address_save_btn'),
                    label: l10n.saveAddress,
                    loadingLabel: l10n.saving,
                    isLoading: form.busy,
                    onPressed: _valid && !form.busy ? _save : null,
                  ),
                  if (widget.firstTime)
                    SnButton(
                      key: const Key('address_skip_btn'),
                      label: l10n.skipForNow,
                      variant: SnButtonVariant.text,
                      onPressed: form.busy
                          ? null
                          : () => context.go(Routes.home),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
