class Post {
  String caption;
  String uploadUrl;
  List<String> likedBy;
  int timeStamp;
  String uploader;
  
  Post(this.caption, this.uploadUrl, this.likedBy, this.timeStamp, this.uploader);

  Map<String, dynamic> toJson() => {
        'caption': caption,
        'uploadUrl': uploadUrl,
        'likedBy': likedBy,
        'timeStamp' : timeStamp,
        'uploader' : uploader,
      };
}