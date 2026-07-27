import '../models/search_result_model.dart';

abstract class SearchRepository {
  /// Retorna a lista de sugestões de autocompletar de texto para a busca
  Future<List<String>> getSearchSuggestions(String query);

  /// Executa a busca completa retornando a lista de resultados formatados
  Future<List<SearchResultModel>> search(String query, {SearchFilterType filter = SearchFilterType.all});
}
