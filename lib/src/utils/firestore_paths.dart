class FirestorePaths {
  static String users() => 'users';
  static String user(String userId) => 'users/$userId';

  static String recipes() => 'recipes';
  static String recipe(String recipeId) => 'recipes/$recipeId';

  static String ratings(String recipeId) => 'recipes/$recipeId/ratings';
  static String rating(String recipeId, String userId) =>
      'recipes/$recipeId/ratings/$userId';

  static String comments(String recipeId) => 'recipes/$recipeId/comments';
  static String comment(String recipeId, String commentId) =>
      'recipes/$recipeId/comments/$commentId';
}
