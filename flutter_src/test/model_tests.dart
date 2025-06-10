import 'dart:convert';

// Import your models here
import 'package:flutter_src/models/core/image.dart';
import 'package:flutter_src/models/core/user.dart';
import 'package:flutter_src/models/core/spot.dart';
import 'package:flutter_src/models/core/spot_list.dart';
import 'package:flutter_src/models/posts/community_post.dart';
import 'package:flutter_src/models/posts/review_post.dart';
import 'package:flutter_src/models/posts/list_post.dart';
import 'package:flutter_src/models/enums/post_type.dart';

/// Simple tests to verify models work correctly
/// Run this as a regular Dart function to test your models
void main() {
  print('🧪 Starting Model Tests...\n');

  testImageModel();
  testUserModel();
  testSpotModel();
  testSpotListModel();
  testCommunityPostModel();
  testReviewPostModel();
  testListPostModel();
  testPostPolymorphism();

  print('✅ All tests completed!');
}

void testImageModel() {
  print('📸 Testing Image Model...');

  // Test JSON data
  final imageJson = {
    'image_id': 1,
    'image_name': 'beach_photo.jpg',
    'blob_url': 'https://storage.com/images/beach.jpg',
    'content_type': 'image/jpeg',
    'file_size': 2048576,
    'created_date': '2024-01-15T10:30:00Z'
  };

  try {
    // Test fromJson
    final image = Image.fromJson(imageJson);
    print('  ✓ Image fromJson works');

    // Test toJson
    final backToJson = image.toJson();
    print('  ✓ Image toJson works');

    // Test helper methods
    print('  ✓ File size in MB: ${image.fileSizeInMB?.toStringAsFixed(2)}');
    print('  ✓ Is JPEG: ${image.isJpeg}');
    print('  ✓ Has valid URL: ${image.hasValidUrl}');

  } catch (e) {
    print('  ❌ Image test failed: $e');
  }
  print('');
}

void testUserModel() {
  print('👤 Testing User Model...');

  final userJson = {
    'user_id': 1,
    'display_name': 'João Silva',
    'username': 'joao123',
    'user_email': 'joao@email.com',
    'hash_password': 'hashed_password_here',
    'creation_date': '2024-01-01T00:00:00Z',
    'last_update_date': '2024-01-15T10:30:00Z',
    'biography': 'Aventureiro apaixonado por natureza',
    'profile_image_id': 1
  };

  try {
    final user = User.fromJson(userJson);
    print('  ✓ User fromJson works');

    final backToJson = user.toJson();
    print('  ✓ User toJson works');

    // Test helper methods
    print('  ✓ Initials: ${user.initials}');
    print('  ✓ Has profile image: ${user.hasProfileImage}');
    print('  ✓ Account age: ${user.accountAgeInDays} days');

  } catch (e) {
    print('  ❌ User test failed: $e');
  }
  print('');
}

void testSpotModel() {
  print('🏞️ Testing Spot Model...');

  final spotJson = {
    'spot_id': 1,
    'spot_name': 'Praia do Rosa',
    'country': 'Brasil',
    'city': 'Imbituba',
    'category': 'Praia',
    'description': 'Uma bela praia no sul de Santa Catarina',
    'created_date': '2024-01-10T00:00:00Z',
    'spot_image_id': 2
  };

  try {
    final spot = Spot.fromJson(spotJson);
    print('  ✓ Spot fromJson works');

    final backToJson = spot.toJson();
    print('  ✓ Spot toJson works');

    // Test helper methods
    print('  ✓ Full location: ${spot.fullLocation}');
    print('  ✓ Location with category: ${spot.locationWithCategory}');
    print('  ✓ Is in Brazil: ${spot.isInCountry('Brasil')}');

  } catch (e) {
    print('  ❌ Spot test failed: $e');
  }
  print('');
}

void testSpotListModel() {
  print('📋 Testing SpotList Model...');

  final listJson = {
    'list_id': 1,
    'list_name': 'Meus Destinos Favoritos',
    'is_public': true
  };

  try {
    final spotList = SpotList.fromJson(listJson);
    print('  ✓ SpotList fromJson works');

    final backToJson = spotList.toJson();
    print('  ✓ SpotList toJson works');

    // Test helper methods
    print('  ✓ Is private: ${spotList.isPrivate}');
    print('  ✓ Visibility status: ${spotList.visibilityStatus}');
    print('  ✓ Name with visibility: ${spotList.nameWithVisibility}');

  } catch (e) {
    print('  ❌ SpotList test failed: $e');
  }
  print('');
}

void testCommunityPostModel() {
  print('🏘️ Testing CommunityPost Model...');

  final communityPostJson = {
    'post_id': 1,
    'description': 'Compartilhando minha lista de praias incríveis!',
    'user_id': 1,
    'created_date': '2024-01-20T15:30:00Z',
    'type': 'community',
    'title': 'Minhas Praias Favoritas',
    'list_id': 1
  };

  try {
    final post = CommunityPost.fromJson(communityPostJson);
    print('  ✓ CommunityPost fromJson works');

    final backToJson = post.toJson();
    print('  ✓ CommunityPost toJson works');

    // Test helper methods
    print('  ✓ Title: ${post.title}');
    print('  ✓ Age in days: ${post.ageInDays}');
    print('  ✓ Has description: ${post.hasDescription}');
    print('  ✓ Post type: ${post.type}');

  } catch (e) {
    print('  ❌ CommunityPost test failed: $e');
  }
  print('');
}

void testReviewPostModel() {
  print('⭐ Testing ReviewPost Model...');

  final reviewPostJson = {
    'post_id': 2,
    'description': 'Lugar incrível! Águas cristalinas e paisagem deslumbrante.',
    'user_id': 1,
    'created_date': '2024-01-21T09:15:00Z',
    'type': 'review',
    'spot_id': 1,
    'rating': 4.5
  };

  try {
    final post = ReviewPost.fromJson(reviewPostJson);
    print('  ✓ ReviewPost fromJson works');

    final backToJson = post.toJson();
    print('  ✓ ReviewPost toJson works');

    // Test helper methods
    print('  ✓ Rating: ${post.rating}');
    print('  ✓ Rating stars: ${post.ratingStars}');
    print('  ✓ Rating description: ${post.ratingDescription}');
    print('  ✓ Is positive review: ${post.isPositiveReview}');
    print('  ✓ Review sentiment: ${post.reviewSentiment}');

    // Test rating validation
    try {
      post.copyWithRating(6.0); // Should throw error
      print('  ❌ Rating validation failed');
    } catch (e) {
      print('  ✓ Rating validation works');
    }

  } catch (e) {
    print('  ❌ ReviewPost test failed: $e');
  }
  print('');
}

void testListPostModel() {
  print('📝 Testing ListPost Model...');

  final listPostJson = {
    'post_id': 3,
    'description': 'Minha coleção pessoal de lugares especiais',
    'user_id': 1,
    'created_date': '2024-01-22T11:45:00Z',
    'type': 'list',
    'title': 'Destinos dos Sonhos',
    'list_id': 2
  };

  try {
    final post = ListPost.fromJson(listPostJson);
    print('  ✓ ListPost fromJson works');

    final backToJson = post.toJson();
    print('  ✓ ListPost toJson works');

    // Test helper methods
    print('  ✓ Title: ${post.title}');
    print('  ✓ Trimmed title: ${post.trimmedTitle}');
    print('  ✓ Has valid title: ${post.hasValidTitle}');

    // Test title validation
    try {
      post.copyWithTitle(''); // Should throw error
      print('  ❌ Title validation failed');
    } catch (e) {
      print('  ✓ Title validation works');
    }

  } catch (e) {
    print('  ❌ ListPost test failed: $e');
  }
  print('');
}

void testPostPolymorphism() {
  print('🔄 Testing Post Polymorphism...');

  // Create different post types
  final posts = [
    {
      'post_id': 1,
      'user_id': 1,
      'created_date': '2024-01-20T15:30:00Z',
      'type': 'community',
      'title': 'Community Title',
      'list_id': 1
    },
    {
      'post_id': 2,
      'user_id': 1,
      'created_date': '2024-01-21T09:15:00Z',
      'type': 'review',
      'spot_id': 1,
      'rating': 4.5
    },
    {
      'post_id': 3,
      'user_id': 1,
      'created_date': '2024-01-22T11:45:00Z',
      'type': 'list',
      'title': 'List Title',
      'list_id': 2
    }
  ];

  try {
    // Test that we can work with different post types polymorphically
    for (final postJson in posts) {
      // Instead of Post.fromJson, we need to manually route based on type
      final type = postJson['type'] as String;

      switch (type) {
        case 'community':
          final post = CommunityPost.fromJson(postJson);
          print('  ✓ ${post.runtimeType}: ${post.title}');
          break;
        case 'review':
          final post = ReviewPost.fromJson(postJson);
          print('  ✓ ${post.runtimeType}: ${post.title}');
          break;
        case 'list':
          final post = ListPost.fromJson(postJson);
          print('  ✓ ${post.runtimeType}: ${post.title}');
          break;
      }
    }

  } catch (e) {
    print('  ❌ Post polymorphism test failed: $e');
  }
  print('');
}

/// Helper function to run a single test
void runSingleTest(String testName, void Function() test) {
  print('Testing $testName...');
  try {
    test();
    print('✅ $testName passed\n');
  } catch (e) {
    print('❌ $testName failed: $e\n');
  }
}