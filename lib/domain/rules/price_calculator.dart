int calculateAmount({required int sackCount, required int pricePerSackUgx}) {
  if (sackCount < 1 || sackCount > 50) {
    throw ArgumentError(
      'Sack count must be between 1 and 50 for a valid pickup.',
    );
  }

  if (pricePerSackUgx < 0) {
    throw ArgumentError('Price per sack cannot be negative.');
  }

  return sackCount * pricePerSackUgx;
}
