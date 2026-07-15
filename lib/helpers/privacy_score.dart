/// Privacy protection labels shown in the Privacy Score card.
const List<String> kPrivacyProtectionLabels = [
  'IP Protected',
  'DNS Protected',
  'No Tracking',
  'Encrypted',
];

/// Target score when the VPN tunnel is connected.
const int kConnectedPrivacyScore = 94;

/// Returns overall privacy score (0–100) based on VPN connection state.
int privacyScoreForConnected(bool isConnected) {
  return isConnected ? kConnectedPrivacyScore : 0;
}

/// Each protection row is fully active only while connected.
double protectionProgressForConnected(bool isConnected) {
  return isConnected ? 1.0 : 0.0;
}
