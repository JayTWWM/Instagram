class User {
  String username;
  int count;

  User(
      this.username,
      this.count);

  

  Map<String, dynamic> toJson() => {
        "username": username,
        "count" : count,
      };
}
