`timescale 1ns/1ns          //时间精度
`define    clock_period 20  //时钟周期

module top_tb;
parameter           H_DISP = 440     ;   //图像宽度
parameter           V_DISP = 400     ;   //图像高度

reg                 clk             ;
reg                 rst_n           ;

wire                VGA_hsync       ;   //VGA行同步
wire                VGA_vsync       ;   //VGA场同步
wire    [23:0]      VGA_data        ;   //VGA数据
wire                VGA_de          ;   //VGA数据使能

wire    [ 7:0]      RGB888_R            ;
wire    [ 7:0]      RGB888_G            ;
wire    [ 7:0]      RGB888_B            ;

assign VGA_data = {RGB888_R , RGB888_G , RGB888_B};

top
#(
    .H_DISP         (H_DISP         ),  //图像宽度
    .V_DISP         (V_DISP         )   //图像高度
)
u_top
(                                     
    .clk            (clk            ), 
    .rst_n          (rst_n          ), 
    
    .VGA_hsync      (VGA_hsync      ),  //VGA行同步
    .VGA_vsync      (VGA_vsync      ),  //VGA场同步
    .VGA_data       ({RGB888_R , RGB888_G , RGB888_B}),  //VGA数据
//    .VGA_data       (VGA_data       ),  //VGA数据
    .VGA_de         (VGA_de         )   //VGA数据使能
);

initial begin
    clk = 1;
    forever
        #(`clock_period/2) clk = ~clk;
end

initial begin
    rst_n = 0; #(`clock_period*20+1);
    rst_n = 1;
end

//  新建txt文件用以存储modelsim仿真数据
integer RGB888_R_txt;
integer RGB888_G_txt;
integer RGB888_B_txt;
integer RGB888_img;

initial 
begin
    RGB888_R_txt = $fopen("./../../matlab/RGB888_R.txt");
    RGB888_G_txt = $fopen("./../../matlab/RGB888_G.txt");
    RGB888_B_txt = $fopen("./../../matlab/RGB888_B.txt");
    RGB888_img = $fopen("./../../matlab/RGB888_img.txt");
end

//  将仿真数据写入txt
reg [20:0] pixel_cnt;

always @(posedge clk) begin
    if(!rst_n) begin
        pixel_cnt <= 0;
    end
    else if(VGA_de) begin
        pixel_cnt = pixel_cnt + 1;
        $fdisplay(RGB888_R_txt,"%d",RGB888_R);
        $fdisplay(RGB888_G_txt,"%d",RGB888_G);
        $fdisplay(RGB888_B_txt,"%d",RGB888_B);
        $fdisplay(RGB888_img,"%d",VGA_data);

        if(pixel_cnt == H_DISP*V_DISP)
            $stop;
    end
end

endmodule