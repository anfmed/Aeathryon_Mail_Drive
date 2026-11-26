/// The organisation and the individual developer(s) are SEPARATE identities:
/// never merge them into one label. Add developers by appending to [developers].
class Credits {
  final String organization;
  final List<String> developers;
  const Credits({required this.organization, required this.developers});
}

const aethryonCredits = Credits(
  organization: 'Aethryon Labs',
  developers: ['Md. Shakil Hossain'],
);
