import 'dart:async';
import 'lib/tsp.dart';


final List<List<double>> table = [
    [100000000.0, 1222.14355582974, 969.6694132357358, 1004.7477548314536, 770.4661803965226, 1058.4310336225042, 928.1364523100309, 1274.5610221378743, 1736.6174649969366, 1439.9251813119245, 2060.8542199416547, 100000000.0],
    [100000000.0, 100000000.0, 274.38648536965565, 268.07958158262323, 994.3005048484541, 809.1648287028522, 302.5622460170494, 116.46961821578962, 515.5868044791955, 286.73076774648655, 881.2951776956547, 1222.14355582974],
    [100000000.0, 274.38648536965565, 100000000.0, 55.056278586114175, 887.3268538572254, 804.4647582361473, 162.70218722256033, 305.36265031239856, 783.0511156111316, 472.89976837265664, 1155.4141809086998, 969.6694132357358],
    [100000000.0, 268.07958158262323, 55.056278586114175, 100000000.0, 942.3245480391832, 856.0585723570432, 215.53199778702754, 277.7301499881632, 763.4333980199752, 435.1781409841568, 1147.0117643891203, 1004.7477548314536],
    [100000000.0, 994.3005048484541, 887.3268538572254, 942.3245480391832, 100000000.0, 357.50653417852755, 738.4812131319081, 1099.7915372945185, 1412.500762250181, 1279.99226683847, 1603.0354126811903, 770.4661803965226],
    [100000000.0, 809.1648287028522, 804.4647582361473, 856.0585723570432, 357.50653417852755, 100000000.0, 641.9141831232603, 924.9266668452605, 1137.3626180052945, 1089.427730342191, 1273.2378854553187, 1058.4310336225042],
    [100000000.0, 302.5622460170494, 162.70218722256033, 215.53199778702754, 738.4812131319081, 641.9141831232603, 100000000.0, 383.11511424958155, 810.3793078151335, 565.2758295156425, 1141.8547544745713, 928.1364523100309],
    [100000000.0, 116.46961821578962, 305.36265031239856, 277.7301499881632, 1099.7915372945185, 924.9266668452605, 383.11511424958155, 100000000.0, 488.3799898958974, 182.73135163919451, 886.7816951201963, 1274.5610221378743],
    [100000000.0, 515.5868044791955, 783.0511156111316, 763.4333980199752, 1412.500762250181, 1137.3626180052945, 810.3793078151335, 488.3799898958974, 100000000.0, 393.34042689972273, 426.86639055744615, 1736.6174649969366],
    [100000000.0, 286.73076774648655, 472.89976837265664, 435.1781409841568, 1279.99226683847, 1089.427730342191, 565.2758295156425, 182.73135163919451, 393.34042689972273, 100000000.0, 818.1241887435334, 1439.9251813119245],
    [100000000.0, 881.2951776956547, 1155.4141809086998, 1147.0117643891203, 1603.0354126811903, 1273.2378854553187, 1141.8547544745713, 886.7816951201963, 426.86639055744615, 818.1241887435334, 100000000.0, 2060.8542199416547],
    [0.0, 100000000.0, 100000000.0, 100000000.0, 100000000.0, 100000000.0, 100000000.0, 100000000.0, 100000000.0, 100000000.0, 100000000.0, 100000000.0]
];

main() {
  BranchAndBound bnb = new BranchAndBound();
  Future<AlgorithmResult> ar = bnb.solve(table);
  ar.then((AlgorithmResult v) => print("Path: ${v.points}, distance: ${v.distance}"));
  /*AntColonyOptimization aco = new AntColonyOptimization();
  aco.solve(table);*/
}