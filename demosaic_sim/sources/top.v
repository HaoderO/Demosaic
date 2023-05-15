`timescale 1 ns/1 ns

module top
#(
    parameter               H_DISP = 640        ,   //  图像宽度
    parameter               V_DISP = 480            //  图像高度
)   
(   
    input   wire            clk                 ,   
    input   wire            rst_n               ,   

    output  wire            VGA_hsync           ,   //  VGA行同步
    output  wire            VGA_vsync           ,   //  VGA场同步
    output  wire    [23:0]  VGA_data            ,   //  VGA数据
    output  wire            VGA_de                  //  VGA数据使能
);  

    wire                    bayer_hsync         ;   //  灰度数据行同步
    wire                    bayer_vsync         ;   //  灰度数据场同步
    wire            [ 7:0]  bayer_data          ;   //  灰度数据
    wire                    bayer_de            ;   //  灰度数据使能

bayerpad_gen
#(
    .H_DISP                 (H_DISP             ),  //  图像宽度
    .V_DISP                 (V_DISP             )   //  图像高度
)   
u_bayerpad_gen 
(   
    .clk                    (clk                ),
    .rst_n                  (rst_n              ),

    .bayer_hsync            (bayer_hsync        ),  //  bayer行同步
    .bayer_vsync            (bayer_vsync        ),  //  bayer场同步
    .bayer_data             (bayer_data         ),  //  bayer数据
    .bayer_de               (bayer_de           )   //  bayer数据使能
);

bayer2rgb
#(
    .H_DISP                 (H_DISP             ),  //  图像宽度
    .V_DISP                 (V_DISP             )   //  图像高度
)   
u_bayer2rgb 
(   
    .clk                    (clk                ),
    .rst_n                  (rst_n              ),

    .bayer_hsync            (bayer_hsync        ),  //  bayer量行同步
    .bayer_vsync            (bayer_vsync        ),  //  bayer量场同步
    .bayer_data             (bayer_data         ),  //  bayer量数据
    .bayer_de               (bayer_de           ),  //  bayer量数据使能

    .RGB888_hsync           (VGA_hsync          ),  //  RGB888行同步
    .RGB888_vsync           (VGA_vsync          ),  //  RGB888场同步
    .RGB888_data            (VGA_data           ),  //  RGB888数据
    .RGB888_de              (VGA_de             )   //  RGB888数据使能
);

endmodule