// RUN: torch-mlir-opt -torch-decompose-complex-ops -split-input-file %s | FileCheck %s

// CHECK-LABEL:  func @matmul_no_decompose
// CHECK:   torch.aten.matmul %arg0, %arg1 : !torch.vtensor<[?,?,?,?,?],f32>, !torch.vtensor<[?,?,?],f32> -> !torch.tensor
func @matmul_no_decompose(%arg0: !torch.vtensor<[?,?,?,?,?],f32>, %arg1: !torch.vtensor<[?,?,?],f32>) -> !torch.tensor {
  %0 = torch.aten.matmul %arg0, %arg1 : !torch.vtensor<[?,?,?,?,?],f32>, !torch.vtensor<[?,?,?],f32> -> !torch.tensor
  return %0 : !torch.tensor
}


// -----

// CHECK-LABEL:  func @matmul_decompose_2d
// CHECK:    torch.aten.mm %arg0, %arg1 : !torch.vtensor<[?,?],f32>, !torch.vtensor<[?,?],f32> -> !torch.tensor
func @matmul_decompose_2d(%arg0: !torch.vtensor<[?,?],f32>, %arg1: !torch.vtensor<[?,?],f32>) -> !torch.tensor {
  %0 = torch.aten.matmul %arg0, %arg1 : !torch.vtensor<[?,?],f32>, !torch.vtensor<[?,?],f32> -> !torch.tensor
  return %0 : !torch.tensor
}

// -----
// CHECK-LABEL:  func @matmul_decompose_3d(
// CHECK:    torch.aten.bmm %arg0, %arg1 : !torch.vtensor<[?,?,?],f32>, !torch.vtensor<[?,?,?],f32> -> !torch.tensor
func @matmul_decompose_3d(%arg0: !torch.vtensor<[?,?,?],f32>, %arg1: !torch.vtensor<[?,?,?],f32>) -> !torch.tensor {
  %0 = torch.aten.matmul %arg0, %arg1 : !torch.vtensor<[?,?,?],f32>, !torch.vtensor<[?,?,?],f32> -> !torch.tensor
  return %0 : !torch.tensor
}

// ----
// CHECK-LABEL:   func @torch.aten.softmax.int(
// CHECK-SAME:                                 %[[T:.*]]: !torch.tensor<[2,3],f32>,
// CHECK-SAME:                                 %[[DIM:.*]]: !torch.int) -> !torch.tensor<[2,3],f32> {
// CHECK:           %[[DTYPE:.*]] = torch.constant.none
// CHECK:           %[[EXP:.*]] = torch.aten.exp %[[T]] : !torch.tensor<[2,3],f32> -> !torch.tensor<[2,3],f32>
// CHECK:           %[[DIM_LIST:.*]] = torch.prim.ListConstruct %[[DIM]] : (!torch.int) -> !torch.list<!torch.int>
// CHECK:           %[[KEEP_DIM:.*]] = torch.constant.bool true
// CHECK:           %[[SUM_DTYPE:.*]] = torch.constant.none
// CHECK:           %[[SUM:.*]] = torch.aten.sum.dim_IntList %[[EXP]], %[[DIM_LIST]], %[[KEEP_DIM]], %[[SUM_DTYPE]] :
// CHECK-SAME:          !torch.tensor<[2,3],f32>, !torch.list<!torch.int>, !torch.bool, !torch.none -> !torch.tensor<[?,?],f32>
// CHECK:           %[[SOFTMAX:.*]] = torch.aten.div.Tensor %[[EXP]], %[[SUM]] : !torch.tensor<[2,3],f32>, !torch.tensor<[?,?],f32> -> !torch.tensor<[2,3],f32>
// CHECK:           %[[RET:.*]] = torch.tensor_static_info_cast %[[SOFTMAX]] : !torch.tensor<[2,3],f32> to !torch.tensor<[2,3],f32>
// CHECK:           return %[[RET]] : !torch.tensor<[2,3],f32>
func @torch.aten.softmax.int(%t: !torch.tensor<[2,3],f32>, %dim: !torch.int) -> !torch.tensor<[2,3],f32> {
  %dtype = torch.constant.none
  %ret = torch.aten.softmax.int %t, %dim, %dtype: !torch.tensor<[2,3],f32>, !torch.int, !torch.none -> !torch.tensor<[2,3],f32>
  return %ret : !torch.tensor<[2,3],f32>
}

// ----
// CHECK-LABEL:   func @torch.aten.softmax.int$cst_dim(
// CHECK-SAME:                                         %[[T:.*]]: !torch.tensor<[2,3],f32>) -> !torch.tensor<[2,3],f32> {
// CHECK:           %[[DTYPE:.*]] = torch.constant.none
// CHECK:           %[[DIM:.*]] = torch.constant.int 1
// CHECK:           %[[EXP:.*]] = torch.aten.exp %[[T]] : !torch.tensor<[2,3],f32> -> !torch.tensor<[2,3],f32>
// CHECK:           %[[DIM_LIST:.*]] = torch.prim.ListConstruct %[[DIM]] : (!torch.int) -> !torch.list<!torch.int>
// CHECK:           %[[KEEP_DIM:.*]] = torch.constant.bool true
// CHECK:           %[[SUM_DTYPE:.*]] = torch.constant.none
// CHECK:           %[[SUM:.*]] = torch.aten.sum.dim_IntList %[[EXP]], %[[DIM_LIST]], %[[KEEP_DIM]], %[[SUM_DTYPE]] :
// CHECK-SAME           !torch.tensor<[2,3],f32>, !torch.list<!torch.int>, !torch.bool, !torch.none -> !torch.tensor<[2,1],f32>
// CHECK:           %[[SOFTMAX:.*]] = torch.aten.div.Tensor %[[EXP]], %[[SUM]] : !torch.tensor<[2,3],f32>, !torch.tensor<[2,1],f32> -> !torch.tensor<[2,3],f32>
// CHECK:           %[[RET:.*]] = torch.tensor_static_info_cast %[[SOFTMAX]] : !torch.tensor<[2,3],f32> to !torch.tensor<[2,3],f32>
// CHECK:           return %[[RET]] : !torch.tensor<[2,3],f32>
func @torch.aten.softmax.int$cst_dim(%t: !torch.tensor<[2,3],f32>) -> !torch.tensor<[2,3],f32> {
  %none = torch.constant.none
  %dim = torch.constant.int 1
  %ret = torch.aten.softmax.int %t, %dim, %none : !torch.tensor<[2,3],f32>, !torch.int, !torch.none -> !torch.tensor<[2,3],f32>
  return %ret : !torch.tensor<[2,3],f32>
}

// ----
// CHECK-LABEL:   func @torch.aten.softmax.int$dyn_shape(
// CHECK-SAME:                                           %[[T:.*]]: !torch.tensor<[?,?],f32>) -> !torch.tensor<[?,?],f32> {
// CHECK:           %[[DTYPE:.*]] = torch.constant.none
// CHECK:           %[[DIM:.*]] = torch.constant.int 1
// CHECK:           %[[EXP:.*]] = torch.aten.exp %[[T]] : !torch.tensor<[?,?],f32> -> !torch.tensor<[?,?],f32>
// CHECK:           %[[DIM_LIST:.*]] = torch.prim.ListConstruct %[[DIM]] : (!torch.int) -> !torch.list<!torch.int>
// CHECK:           %[[KEEP_DIM:.*]] = torch.constant.bool true
// CHECK:           %[[SUM_DTYPE:.*]] = torch.constant.none
// CHECK:           %[[SUM:.*]] = torch.aten.sum.dim_IntList %[[EXP]], %[[DIM_LIST]], %[[KEEP_DIM]], %[[SUM_DTYPE]] :
// CHECK-SAME:          !torch.tensor<[?,?],f32>, !torch.list<!torch.int>, !torch.bool, !torch.none -> !torch.tensor<[?,1],f32>
// CHECK:           %[[SOFTMAX:.*]] = torch.aten.div.Tensor %[[EXP]], %[[SUM]] : !torch.tensor<[?,?],f32>, !torch.tensor<[?,1],f32> -> !torch.tensor<[?,?],f32>
// CHECK:           %[[RET:.*]] = torch.tensor_static_info_cast %[[SOFTMAX]] : !torch.tensor<[?,?],f32> to !torch.tensor<[?,?],f32>
// CHECK:           return %[[RET]] : !torch.tensor<[?,?],f32>
func @torch.aten.softmax.int$dyn_shape(%t: !torch.tensor<[?,?],f32>) -> !torch.tensor<[?,?],f32> {
  %none = torch.constant.none
  %dim = torch.constant.int 1
  %ret = torch.aten.softmax.int %t, %dim, %none : !torch.tensor<[?,?],f32>, !torch.int, !torch.none -> !torch.tensor<[?,?],f32>
  return %ret : !torch.tensor<[?,?],f32>
}

// ----
// CHECK-LABEL:   func @torch.aten.softmax.int$unknown_shape(
// CHECK-SAME:                                               %[[T:.*]]: !torch.tensor<*,f32>) -> !torch.tensor<*,f32> {
// CHECK:           %[[DTYPE:.*]] = torch.constant.none
// CHECK:           %[[DIM:.*]] = torch.constant.int 1
// CHECK:           %[[EXP:.*]] = torch.aten.exp %[[T]] : !torch.tensor<*,f32> -> !torch.tensor<*,f32>
// CHECK:           %[[DIM_LIST:.*]] = torch.prim.ListConstruct %[[DIM]] : (!torch.int) -> !torch.list<!torch.int>
// CHECK:           %[[KEEP_DIM:.*]] = torch.constant.bool true
// CHECK:           %[[SUM_DTYPE:.*]] = torch.constant.none
// CHECK:           %[[SUM:.*]] = torch.aten.sum.dim_IntList %[[EXP]], %[[DIM_LIST]], %[[KEEP_DIM]], %[[SUM_DTYPE]] :
// CHECK-SAME:          !torch.tensor<*,f32>, !torch.list<!torch.int>, !torch.bool, !torch.none -> !torch.tensor<*,f32>
// CHECK:           %[[SOFTMAX:.*]] = torch.aten.div.Tensor %[[EXP]], %[[SUM]] : !torch.tensor<*,f32>, !torch.tensor<*,f32> -> !torch.tensor<*,f32>
// CHECK:           %[[RET:.*]] = torch.tensor_static_info_cast %[[SOFTMAX]] : !torch.tensor<*,f32> to !torch.tensor<*,f32>
// CHECK:           return %[[RET]] : !torch.tensor<*,f32>
func @torch.aten.softmax.int$unknown_shape(%t: !torch.tensor<*,f32>) -> !torch.tensor<*,f32> {
  %none = torch.constant.none
  %dim = torch.constant.int 1
  %ret = torch.aten.softmax.int %t, %dim, %none : !torch.tensor<*,f32>, !torch.int, !torch.none -> !torch.tensor<*,f32>
  return %ret : !torch.tensor<*,f32>
}

// ----
// CHECK-LABEL:   func @torch.aten.size(
// CHECK-SAME:                         %[[T:.*]]: !torch.vtensor<[?,3],f32>) -> !torch.list<!torch.int> {
// CHECK:           %[[CST0:.*]] = torch.constant.int 0
// CHECK:           %[[DIM0:.*]] = torch.aten.size.int %[[T]], %[[CST0]] : !torch.vtensor<[?,3],f32>, !torch.int -> !torch.int
// CHECK:           %[[CST1:.*]] = torch.constant.int 1
// CHECK:           %[[DIM1:.*]] = torch.aten.size.int %[[T]], %[[CST1]] : !torch.vtensor<[?,3],f32>, !torch.int -> !torch.int
// CHECK:           %[[SIZE:.*]] = torch.prim.ListConstruct %[[DIM0]], %[[DIM1]] : (!torch.int, !torch.int) -> !torch.list<!torch.int>
// CHECK:           return %[[SIZE]] : !torch.list<!torch.int>
func @torch.aten.size(%arg0: !torch.vtensor<[?,3],f32>) -> !torch.list<!torch.int> {
  %0 = torch.aten.size %arg0 : !torch.vtensor<[?,3],f32> -> !torch.list<!torch.int>
  return %0 : !torch.list<!torch.int>
}
