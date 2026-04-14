import 'package:vcom_app/features/hub/data/models/comment_model.dart';
import 'package:vcom_app/features/hub/data/models/post_model.dart';

abstract class HubRemoteDataSource {
  Future<List<PostModel>> getPosts({int page = 1, int perPage = 20});

  Future<PostModel> getPostDetail(int postId);

  Future<PostModel> createPost({
    required String title,
    required String content,
    required String visibility,
  });

  Future<PostModel> updatePost({
    required int postId,
    required String title,
    required String content,
    required String visibility,
  });

  Future<void> deletePost(int postId);

  Future<CommentModel> createComment({
    required int postId,
    required String content,
  });

  Future<ReactionModel> createReaction({
    required int postId,
    required String type,
  });
}

class HubRemoteDataSourceImpl implements HubRemoteDataSource {
  @override
  Future<List<PostModel>> getPosts({int page = 1, int perPage = 20}) async {
    throw UnimplementedError();
  }

  @override
  Future<PostModel> getPostDetail(int postId) {
    throw UnimplementedError();
  }

  @override
  Future<PostModel> createPost({
    required String title,
    required String content,
    required String visibility,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<PostModel> updatePost({
    required int postId,
    required String title,
    required String content,
    required String visibility,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deletePost(int postId) {
    throw UnimplementedError();
  }

  @override
  Future<CommentModel> createComment({
    required int postId,
    required String content,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ReactionModel> createReaction({
    required int postId,
    required String type,
  }) {
    throw UnimplementedError();
  }
}
