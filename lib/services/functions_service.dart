import 'package:cloud_functions/cloud_functions.dart';
import '../config/backend.dart';

class FunctionsService {
  FunctionsService({FirebaseFunctions? functions})
      : functions = functions ??
            FirebaseFunctions.instanceFor(region: BackendConfig.firebaseRegion);

  final FirebaseFunctions functions;
}
