// RUN: onnx-mlir-opt --march=z16 --maccel=NNPA --shape-inference --convert-onnx-to-krnl --canonicalize %s -split-input-file | FileCheck %s

// -----


func.func @should_lower_to_zlow(%arg0: tensor<1x3x5x7xf32>) -> tensor<*xf32> {
  %0 = "zhigh.Stick"(%arg0) {layout = "NHWC"} : (tensor<1x3x5x7xf32>) -> tensor<*xf16>
  %1 = "zhigh.Unstick"(%0) : (tensor<*xf16>) -> tensor<*xf32>
  return %1 : tensor<*xf32>

// mlir2FileCheck.py
// CHECK-DAG:   [[MAP_0_:#.+]] = affine_map<(d0, d1, d2, d3) -> (d0, d3 floordiv 64, d1, d2 floordiv 32, d2 mod 32, d3 mod 64)>
// CHECK-LABEL:  func.func @should_lower_to_zlow
// CHECK-SAME:   ([[PARAM_0_:%.+]]: memref<1x3x5x7xf32>) -> memref<1x3x5x7xf32> {
// CHECK-DAG:       [[RES_:%.+]] = memref.alloc() {{.*}}: memref<1x5x7x3xf16, #map>
// CHECK-DAG:       [[RES_1_:%.+]] = memref.alloc() {{.*}}: memref<1x5x7x3xf32>
// CHECK-DAG:       [[LOOP_0_:%.+]]:4 = krnl.define_loops 4
// CHECK:           [[BLOCK_TILE__0_:%.+]], [[BLOCK_IN__0_:%.+]] = krnl.block [[LOOP_0_]]#3 3 : (!krnl.loop) -> (!krnl.loop, !krnl.loop)
// CHECK:           krnl.unroll [[BLOCK_IN__0_]] : !krnl.loop
// CHECK:           krnl.iterate([[LOOP_0_]]#0, [[LOOP_0_]]#1, [[LOOP_0_]]#2, [[BLOCK_TILE__0_]], [[BLOCK_IN__0_]]) with ([[LOOP_0_]]#0 -> [[I_0_:%.+]] = 0 to 1, [[LOOP_0_]]#1 -> [[I_1_:%.+]] = 0 to 5, [[LOOP_0_]]#2 -> [[I_2_:%.+]] = 0 to 7, [[LOOP_0_]]#3 -> [[I_3_:%.+]] = 0 to 3){
// CHECK:             [[LOAD_PARAM_0_MEM_:%.+]] = krnl.load [[PARAM_0_]]{{.}}[[I_0_]], [[I_3_]], [[I_1_]], [[I_2_]]{{.}} : memref<1x3x5x7xf32>
// CHECK:             krnl.store [[LOAD_PARAM_0_MEM_]], [[RES_1_]]{{.}}[[I_0_]], [[I_1_]], [[I_2_]], [[I_3_]]{{.}} : memref<1x5x7x3xf32>
// CHECK:           }
// CHECK:           "zlow.stick"([[RES_1_]], [[RES_]]) {layout = "NHWC"} : (memref<1x5x7x3xf32>, memref<1x5x7x3xf16, #map>) -> ()
// CHECK:           [[RES_2_:%.+]] = memref.alloc() {{.*}}: memref<1x5x7x3xf32>
// CHECK:           "zlow.unstick"([[RES_]], [[RES_]]_1) {layout = "NHWC"} : (memref<1x5x7x3xf16, #map>, memref<1x5x7x3xf32>) -> ()
// CHECK-DAG:       [[RES_3_:%.+]] = memref.alloc() {{.*}}: memref<1x3x5x7xf32>
// CHECK-DAG:       [[LOOP_1_:%.+]]:4 = krnl.define_loops 4
// CHECK:           [[BLOCK_TILE__1_:%.+]], [[BLOCK_IN__1_:%.+]] = krnl.block [[LOOP_1_]]#3 7 : (!krnl.loop) -> (!krnl.loop, !krnl.loop)
// CHECK:           krnl.unroll [[BLOCK_IN__1_]] : !krnl.loop
// CHECK:           krnl.iterate([[LOOP_1_]]#0, [[LOOP_1_]]#1, [[LOOP_1_]]#2, [[BLOCK_TILE__1_]], [[BLOCK_IN__1_]]) with ([[LOOP_1_]]#0 -> [[I_4_:%.+]] = 0 to 1, [[LOOP_1_]]#1 -> [[I_5_:%.+]] = 0 to 3, [[LOOP_1_]]#2 -> [[I_6_:%.+]] = 0 to 5, [[LOOP_1_]]#3 -> [[I_7_:%.+]] = 0 to 7){
// CHECK:             [[LOAD_PARAM_0_MEM_1_:%.+]] = krnl.load [[RES_2_]]{{.}}[[I_4_]], [[I_6_]], [[I_7_]], [[I_5_]]{{.}} : memref<1x5x7x3xf32>
// CHECK:             krnl.store [[LOAD_PARAM_0_MEM_1_]], [[RES_3_]]{{.}}[[I_4_]], [[I_5_]], [[I_6_]], [[I_7_]]{{.}} : memref<1x3x5x7xf32>
// CHECK:           }
// CHECK:           return [[RES_3_]] : memref<1x3x5x7xf32>
// CHECK:         }
}

// -----


func.func @should_lower_to_zlow_unknown_dims(%arg0: tensor<1x?x?x7xf32>) -> tensor<*xf32> {
  %0 = "zhigh.Stick"(%arg0) {layout = "NHWC"} : (tensor<1x?x?x7xf32>) -> tensor<*xf16>
  %1 = "zhigh.Unstick"(%0) : (tensor<*xf16>) -> tensor<*xf32>
  return %1 : tensor<*xf32>

// mlir2FileCheck.py
// CHECK-DAG:   [[MAP_0_:#.+]] = affine_map<(d0, d1, d2, d3) -> (d0, d3 floordiv 64, d1, d2 floordiv 32, d2 mod 32, d3 mod 64)>
// CHECK-DAG:   [[MAP_1_:#.+]] = affine_map<(d0) -> (d0)>
// CHECK-DAG:   [[MAP_2_:#.+]] = affine_map<(d0, d1) -> (d1)>
// CHECK-LABEL:  func.func @should_lower_to_zlow_unknown_dims
// CHECK-SAME:   ([[PARAM_0_:%.+]]: memref<1x?x?x7xf32>) -> memref<1x?x?x7xf32> {
// CHECK-DAG:       [[CST_2_:%.+]] = arith.constant 2 : index
// CHECK-DAG:       [[CST_1_:%.+]] = arith.constant 1 : index
// CHECK-NOT: separator of consecutive DAGs
// CHECK-DAG:       [[VAR_dim_:%.+]] = memref.dim [[PARAM_0_]], [[CST_1_]] : memref<1x?x?x7xf32>
// CHECK-DAG:       [[VAR_dim_0_:%.+]] = memref.dim [[PARAM_0_]], [[CST_2_]] : memref<1x?x?x7xf32>
// CHECK-NOT: separator of consecutive DAGs
// CHECK-DAG:       [[RES_:%.+]] = memref.alloc([[VAR_dim_0_]], [[VAR_dim_]]) {{.*}}: memref<1x?x7x?xf16, #map>
// CHECK-DAG:       [[VAR_dim_1_:%.+]] = memref.dim [[PARAM_0_]], [[CST_2_]] : memref<1x?x?x7xf32>
// CHECK-DAG:       [[VAR_dim_2_:%.+]] = memref.dim [[PARAM_0_]], [[CST_1_]] : memref<1x?x?x7xf32>
// CHECK-NOT: separator of consecutive DAGs
// CHECK-DAG:       [[RES_1_:%.+]] = memref.alloc([[VAR_dim_1_]], [[VAR_dim_2_]]) {{.*}}: memref<1x?x7x?xf32>
// CHECK-DAG:       [[LOOP_0_:%.+]]:4 = krnl.define_loops 4
// CHECK:           krnl.iterate([[LOOP_0_]]#0, [[LOOP_0_]]#1, [[LOOP_0_]]#2, [[LOOP_0_]]#3) with ([[LOOP_0_]]#0 -> [[I_0_:%.+]] = 0 to 1, [[LOOP_0_]]#1 -> [[I_1_:%.+]] = 0 to [[MAP_1_]]([[VAR_dim_1_]]), [[LOOP_0_]]#2 -> [[I_2_:%.+]] = 0 to 7, [[LOOP_0_]]#3 -> [[I_3_:%.+]] = 0 to [[MAP_2_]]([[VAR_dim_1_]], [[VAR_dim_2_]])){
// CHECK:             [[LOAD_PARAM_0_MEM_:%.+]] = krnl.load [[PARAM_0_]]{{.}}[[I_0_]], [[I_3_]], [[I_1_]], [[I_2_]]{{.}} : memref<1x?x?x7xf32>
// CHECK:             krnl.store [[LOAD_PARAM_0_MEM_]], [[RES_1_]]{{.}}[[I_0_]], [[I_1_]], [[I_2_]], [[I_3_]]{{.}} : memref<1x?x7x?xf32>
// CHECK:           }
// CHECK:           "zlow.stick"([[RES_1_]], [[RES_]]) {layout = "NHWC"} : (memref<1x?x7x?xf32>, memref<1x?x7x?xf16, #map>) -> ()
// CHECK:           [[RES_2_:%.+]] = memref.alloc([[VAR_dim_0_]], [[VAR_dim_]]) {{.*}}: memref<1x?x7x?xf32>
// CHECK:           "zlow.unstick"([[RES_]], [[RES_]]_4) {layout = "NHWC"} : (memref<1x?x7x?xf16, #map>, memref<1x?x7x?xf32>) -> ()
// CHECK-DAG:       [[RES_3_:%.+]] = memref.alloc([[VAR_dim_]], [[VAR_dim_]]_0) {{.*}}: memref<1x?x?x7xf32>
// CHECK-DAG:       [[LOOP_1_:%.+]]:4 = krnl.define_loops 4
// CHECK:           [[BLOCK_TILE__0_:%.+]], [[BLOCK_IN__0_:%.+]] = krnl.block [[LOOP_1_]]#3 7 : (!krnl.loop) -> (!krnl.loop, !krnl.loop)
// CHECK:           krnl.unroll [[BLOCK_IN__0_]] : !krnl.loop
// CHECK:           krnl.iterate([[LOOP_1_]]#0, [[LOOP_1_]]#1, [[LOOP_1_]]#2, [[BLOCK_TILE__0_]], [[BLOCK_IN__0_]]) with ([[LOOP_1_]]#0 -> [[I_4_:%.+]] = 0 to 1, [[LOOP_1_]]#1 -> [[I_5_:%.+]] = 0 to [[MAP_1_]]([[VAR_dim_]]), [[LOOP_1_]]#2 -> [[I_6_:%.+]] = 0 to [[MAP_2_]]([[VAR_dim_]], [[VAR_dim_]]_0), [[LOOP_1_]]#3 -> [[I_7_:%.+]] = 0 to 7){
// CHECK:             [[LOAD_PARAM_0_MEM_1_:%.+]] = krnl.load [[RES_2_]]{{.}}[[I_4_]], [[I_6_]], [[I_7_]], [[I_5_]]{{.}} : memref<1x?x7x?xf32>
// CHECK:             krnl.store [[LOAD_PARAM_0_MEM_1_]], [[RES_3_]]{{.}}[[I_4_]], [[I_5_]], [[I_6_]], [[I_7_]]{{.}} : memref<1x?x?x7xf32>
// CHECK:           }
// CHECK:           return [[RES_3_]] : memref<1x?x?x7xf32>
// CHECK:         }
}

