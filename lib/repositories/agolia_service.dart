import 'package:algolia/algolia.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';

class AlgoliaService {

  static final Algolia _algolia = Algolia.init(
    applicationId: Constants.agoliaApplicationId,
    apiKey: Constants.agoliaApiKey,
  );

  static final Algolia algolia = _algolia.instance;

  static Future<List<String>> searchCustomer(String query, { int page = 0, int hitsPerPage = 25 }) async {

    AlgoliaQuery algoliaQuery = _algolia.instance
        .index(Constants.indexSearchCustomer)
        .query(query)
        .setPage(page)
        .setHitsPerPage(hitsPerPage);

    AlgoliaQuerySnapshot snap = await algoliaQuery.getObjects();
    return snap.hits.map((hit) => hit.objectID).toList();
  }
}