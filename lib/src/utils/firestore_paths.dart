class FirestorePaths {
  static String users() => 'users';
  static String user(String userId) => 'users/$userId';

  // --- OLD (خليه دابا) ---
  static String recipes() => 'recipes';
  static String recipe(String recipeId) => 'recipes/$recipeId';
  static String ratings(String recipeId) => 'recipes/$recipeId/ratings';
  static String rating(String recipeId, String userId) =>
      'recipes/$recipeId/ratings/$userId';
  static String comments(String recipeId) => 'recipes/$recipeId/comments';
  static String comment(String recipeId, String commentId) =>
      'recipes/$recipeId/comments/$commentId';

  // --- NEW (ديال match app) ---
  static String places() => 'places';
  static String place(String placeId) => 'places/$placeId';

  static String stadiums() => 'stadiums';
  static String stadium(String stadiumId) => 'stadiums/$stadiumId';

  static String matches() => 'matches';
  static String match(String matchId) => 'matches/$matchId';

  // participants subcollection
  static String participants(String matchId) => 'matches/$matchId/participants';
  static String participant(String matchId, String playerId) =>
      'matches/$matchId/participants/$playerId';

  // messages subcollection
  static String messages(String matchId) => 'matches/$matchId/messages';
  static String message(String matchId, String messageId) =>
      'matches/$matchId/messages/$messageId';
}
