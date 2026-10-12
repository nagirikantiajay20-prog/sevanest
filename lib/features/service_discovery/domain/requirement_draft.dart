/// The customer's in-progress requirement. Built by modules 3-4, read by Review and Results.
/// Module 3 adds the remaining fields and persistence; Home only needs to reset / preset it.
class RequirementDraft {
  const RequirementDraft({this.serviceId});

  final String? serviceId;
}
