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
import 'package:sevanest_customer/core/widgets/sn_header.dart';
import 'package:sevanest_customer/core/widgets/sn_states.dart';
import 'package:sevanest_customer/features/addresses/domain/address.dart';
import 'package:sevanest_customer/features/addresses/presentation/providers/address_providers.dart';
import 'package:sevanest_customer/features/addresses/presentation/widgets/address_form_widgets.dart';
import 'package:sevanest_customer/features/addresses/presentation/widgets/home_photo_field.dart';
import 'package:sevanest_customer/features/authentication/presentation/screens/splash_screen.dart'
    show splashHoldProvider;
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/motion.dart';
import 'package:sevanest_customer/features/customer_profile/domain/customer_photo.dart';
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
    final title = id == null ? l10n.addAddress : l10n.editAddressTitle;
    if (id == null) {
      return Scaffold(
        backgroundColor: AppColors.canvasCool,
        body: Column(
          children: [
            SnHeader(
              title: title,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: _AddressForm(firstTime: firstTime, prefill: prefill),
            ),
          ],
        ),
      );
    }
    final list = ref.watch(addressesProvider);
    return Scaffold(
      backgroundColor: AppColors.canvasCool,
      body: Column(
        children: [
          SnHeader(
            title: title,
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: AsyncValueView<List<Address>>(
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
          ),
        ],
      ),
    );
  }
}

/// The add-address bottom sheet of design screen 08 (same form as `/addresses/new`). Resolves to
/// the saved [Address], or null when closed.
Future<Address?> showAddAddressSheet(
  BuildContext context, {
  AddressInput? prefill,
}) => _showAddressSheet<Address>(context, prefill: prefill);

/// The same sheet for profile setup, where the profile does not exist yet: nothing is saved, the
/// typed address and its (mandatory) home photo come back for the caller to save once the profile
/// exists.
Future<CollectedAddress?> showCollectAddressSheet(
  BuildContext context, {
  AddressInput? initial,
  PickedPhoto? initialPhoto,
}) => _showAddressSheet<CollectedAddress>(
  context,
  prefill: initial,
  photo: initialPhoto,
  collect: true,
);

/// What the profile-setup address sheet hands back.
typedef CollectedAddress = ({AddressInput input, PickedPhoto photo});

Future<T?> _showAddressSheet<T>(
  BuildContext context, {
  AddressInput? prefill,
  PickedPhoto? photo,
  bool collect = false,
}) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    barrierColor: const Color(0x610F2340),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(ctx).height * 0.9,
        child: AddressSheetFrame(
          title: l10n.addAddress,
          child: _AddressForm(
            firstTime: false,
            prefill: prefill,
            initialPhoto: photo,
            inSheet: true,
            collect: collect,
          ),
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
    this.initialPhoto,
    this.inSheet = false,
    this.collect = false,
  });
  final bool inSheet;

  /// Profile setup: return the typed [AddressInput] instead of saving it.
  final bool collect;
  final AddressInput? prefill;

  /// Photo chosen earlier in profile setup, kept when the sheet is reopened.
  final PickedPhoto? initialPhoto;
  final Address? initial;
  final bool firstTime;

  @override
  ConsumerState<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends ConsumerState<_AddressForm>
    with SingleTickerProviderStateMixin {
  static final _fill = Colors.white.withValues(alpha: 0.8);
  late final _clock = ScreenClock(
    this,
    motion: ref.read(splashHoldProvider) > Duration.zero,
  );
  bool _locationFound = false;
  bool _areaOpen = false;
  late final _label = TextEditingController(text: widget.initial?.label ?? '');
  late final _house = TextEditingController(
    text: widget.initial == null
        ? (widget.prefill?.line ?? '')
        : _parts(widget.initial).$1,
  );
  late final _street = TextEditingController(
    text: widget.initial == null
        ? (widget.prefill?.line2 ?? '')
        : _parts(widget.initial).$2,
  );
  late final _area = TextEditingController(
    text: widget.initial?.area ?? widget.prefill?.area ?? '',
  );
  late final _city = TextEditingController(
    text: widget.initial?.city ?? widget.prefill?.city ?? defaultCity,
  );
  late final _pincode = TextEditingController(
    text: widget.initial?.pincode ?? widget.prefill?.pincode ?? '',
  );
  late bool _default = widget.initial?.isDefault ?? widget.collect;
  late double? _lat = widget.prefill?.latitude;
  late double? _lng = widget.prefill?.longitude;
  bool _locating = false;
  bool _locationOff = false;
  bool _defaultTouched = false;

  /// A photo chosen in this session (uploaded on save) / the saved one removed by the customer.
  late PickedPhoto? _photo = widget.initialPhoto;
  bool _photoRemoved = false;

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
    if (!_isEdit && !widget.collect) {
      ref.read(addressesProvider.future).then((list) {
        if (mounted && list.isEmpty && !_defaultTouched) {
          setState(() => _default = true);
        }
      }, onError: (_) {});
    }
  }

  @override
  void dispose() {
    _clock.dispose();
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
          _defaultTouched ||
          _photo != null;
    }
    final (house, street) = _parts(a);
    return _house.text.trim() != house ||
        _street.text.trim() != street ||
        _label.text.trim() != (a.label ?? '') ||
        _area.text.trim() != a.area ||
        _city.text.trim() != a.city ||
        _pincode.text.trim() != a.pincode ||
        _default != a.isDefault ||
        _photo != null ||
        _photoRemoved;
  }

  /// The home photo is mandatory: a new pick, or the saved one not removed.
  bool get _hasPhoto =>
      _photo != null ||
      (!_photoRemoved && (_initial?.photoUrl?.isNotEmpty ?? false));

  bool get _fieldsValid =>
      _house.text.trim().isNotEmpty &&
      _street.text.trim().isNotEmpty &&
      _area.text.trim().isNotEmpty &&
      _city.text.trim().isNotEmpty &&
      isValidPincode(_pincode.text);

  bool get _valid => _fieldsValid && _hasPhoto;

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
      _locationFound = false;
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
      _locationFound = true;
    });
  }

  Future<void> _save() async {
    if (!_valid) return;
    if (widget.collect) {
      Navigator.of(context).pop((
        input: AddressInput(
          line: _house.text.trim(),
          line2: _street.text.trim(),
          label: _label.text,
          area: _area.text,
          city: _city.text,
          pincode: _pincode.text,
          isDefault: true,
          latitude: _lat,
          longitude: _lng,
        ),
        photo: _photo!,
      ));
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final savedText = AppLocalizations.of(context).addressSaved;
    final photoFailedText = AppLocalizations.of(context).homePhotoUploadFailed;
    final saved = await ref
        .read(addressFormProvider.notifier)
        .save(
          id: _initial?.id,
          makeDefault: _isEdit && _default && !_initial!.isDefault,
          photo: _photo,
          removePhoto: _photoRemoved && _photo == null,
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
    final photoFailed =
        ref.read(addressFormProvider.notifier).photoFailure != null;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(photoFailed ? photoFailedText : savedText)),
      );
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
                    AddressLocationCard(
                      clock: _clock,
                      locating: _locating,
                      found: _locationFound,
                      failed: _locationOff,
                      onTap: form.busy || _locating
                          ? null
                          : _useCurrentLocation,
                    ),
                    if (_locationOff)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Text(
                          l10n.addressLocationFailed,
                          key: const Key('address_location_error'),
                          style: const TextStyle(
                            color: Color(0xFFB91C1C),
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                      ),
                    if (_locationFound) ...[
                      const SizedBox(height: 12),
                      AddressFoundMap(
                        clock: _clock,
                        caption:
                            '${_area.text} \u00b7 ${_city.text} ${_pincode.text}',
                      ),
                    ],
                    const SizedBox(height: 18),
                  ],
                  LabeledField(
                    fill: _fill,
                    name: 'address_label_field',
                    label: l10n.addressLabelName,
                    optionalInline: l10n.labelOptional,
                    prefixIcon: Icons.home_outlined,
                    hint: l10n.addressLabelHint,
                    controller: _label,
                    enabled: !form.busy,
                    maxLength: 40,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  AddressLabelChips(
                    current: _label.text,
                    onPick: form.busy
                        ? null
                        : (t) => setState(() => _label.text = t),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  LabeledField(
                    fill: _fill,
                    name: 'address_line1_field',
                    label: l10n.houseLabel,
                    requiredMark: true,
                    prefixIcon: Icons.apartment_outlined,
                    hint: l10n.houseHint,
                    controller: _house,
                    enabled: !form.busy,
                    textInputAction: TextInputAction.next,
                    error: fieldErrors['line'],
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  LabeledField(
                    fill: _fill,
                    name: 'address_line2_field',
                    label: l10n.streetLabel,
                    requiredMark: true,
                    prefixIcon: Icons.location_on_outlined,
                    hint: l10n.streetHint,
                    controller: _street,
                    enabled: !form.busy,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  LabeledField(
                    fill: _fill,
                    name: 'address_area_field',
                    label: l10n.areaLabel,
                    requiredMark: true,
                    prefixIcon: Icons.map_outlined,
                    hint: l10n.areaHint,
                    controller: _area,
                    enabled: !form.busy,
                    readOnly: picker,
                    onTap: picker
                        ? () => setState(() => _areaOpen = !_areaOpen)
                        : null,
                    suffixIcon: picker
                        ? AnimatedRotation(
                            turns: _areaOpen ? 0.5 : 0,
                            duration: const Duration(milliseconds: 250),
                            child: const Icon(Icons.expand_more_rounded),
                          )
                        : null,
                    helper: areas.hasError ? l10n.areasUnavailable : null,
                    error: fieldErrors['area'],
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                  ),
                  if (picker && _areaOpen)
                    AddressAreaList(
                      names: [for (final a in areaList) a.name],
                      selected: _area.text.trim(),
                      onPick: (n) => setState(() {
                        _area.text = n;
                        _areaOpen = false;
                      }),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: LabeledField(
                          fill: _fill,
                          name: 'address_city_field',
                          label: l10n.cityLabel,
                          requiredMark: true,
                          controller: _city,
                          enabled: !form.busy,
                          textInputAction: TextInputAction.next,
                          error: fieldErrors['city'],
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LabeledField(
                          fill: _fill,
                          name: 'address_pincode_field',
                          label: l10n.pincodeLabel,
                          requiredMark: true,
                          hint: l10n.pincodeHint,
                          controller: _pincode,
                          enabled: !form.busy,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          maxLength: 6,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          error: pincodeBad
                              ? l10n.pincodeInvalid
                              : fieldErrors['pincode'],
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ...[
                    HomePhotoField(
                      showRequired: _fieldsValid,
                      photo: _photo,
                      url: _photoRemoved ? null : _initial?.photoUrl,
                      enabled: !form.busy,
                      onPicked: (p) => setState(() {
                        _photo = p;
                        _photoRemoved = false;
                      }),
                      onRemoved: () => setState(() {
                        _photo = null;
                        _photoRemoved = true;
                      }),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  SwitchListTile(
                    key: const Key('address_default_switch'),
                    contentPadding: EdgeInsets.zero,
                    activeTrackColor: AppColors.teal,
                    inactiveTrackColor: const Color(0xFF94A3B8),
                    thumbColor: const WidgetStatePropertyAll(Colors.white),
                    trackOutlineColor: const WidgetStatePropertyAll(
                      Colors.transparent,
                    ),
                    title: Text(
                      l10n.setAsDefault,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: authNavy,
                      ),
                    ),
                    subtitle: Text(
                      _initial?.isDefault ?? false
                          ? l10n.alreadyDefault
                          : l10n.setAsDefaultSub,
                    ),
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
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              border: Border(
                top: BorderSide(color: authNavy.withValues(alpha: 0.08)),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.s12,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AuthCta(
                      key: const Key('address_save_btn'),
                      clock: _clock,
                      breathe: true,
                      showArrow: false,
                      radius: 17,
                      label: l10n.saveAddress,
                      loadingLabel: l10n.saving,
                      loading: form.busy,
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
          ),
        ],
      ),
    );
  }
}
