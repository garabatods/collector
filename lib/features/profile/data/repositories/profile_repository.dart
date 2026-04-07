import '../../../../core/data/json_map.dart';
import '../../../../core/data/supabase_repository.dart';
import '../models/profile_model.dart';

class ProfileRepository extends SupabaseRepository {
  ProfileRepository({super.client});

  Future<ProfileModel?> fetchCurrentProfile() async {
    final data = await client
        .from('profiles')
        .select()
        .eq('id', currentUserId)
        .maybeSingle();

    if (data == null) {
      return null;
    }

    return ProfileModel.fromJson(asJsonMap(data));
  }

  Future<ProfileModel> save(ProfileModel profile) async {
    final data = await client
        .from('profiles')
        .upsert(
          profile.toUpsertJson(userId: currentUserId),
          onConflict: 'id',
        )
        .select()
        .single();

    return ProfileModel.fromJson(asJsonMap(data));
  }
}
