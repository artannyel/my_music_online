import 'models/home_section_model.dart';

/// Contrato para busca de seções e recomendações da Home.
abstract class HomeRepository {
  Future<List<HomeSectionModel>> getHomeSections();
}
