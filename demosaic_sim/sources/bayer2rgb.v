module bayer2rgb
#(
    parameter H_DISP            = 12'd640           ,   //  图像宽度
    parameter V_DISP            = 12'd480               //  图像高度
)   
(   
    input   wire                clk                 ,   
    input   wire                rst_n               ,   
    input   wire                bayer_hsync         ,   //  bayer量场同步
    input   wire                bayer_vsync         ,   //  bayer量数据
    input   wire    [ 7:0]      bayer_data          ,   //  bayer量数据使能
    input   wire                bayer_de            ,   //  bayer量行同步

    output  wire                RGB888_hsync        ,   //  输出数据场同步
    output  wire                RGB888_vsync        ,   //  输出数据
    output  wire    [23:0]      RGB888_data         ,   //  输出数据使能
    output  wire                RGB888_de               //  输出数据行同步
);

//  矩阵顺序
//  {matrix_11, matrix_12, matrix_13}
//  {matrix_21, matrix_22, matrix_23}
//  {matrix_31, matrix_32, matrix_33}
    wire            [ 7:0]      matrix_11           ;
    wire            [ 7:0]      matrix_12           ;
    wire            [ 7:0]      matrix_13           ;
    wire            [ 7:0]      matrix_21           ;
    wire            [ 7:0]      matrix_22           ;
    wire            [ 7:0]      matrix_23           ;
    wire            [ 7:0]      matrix_31           ;
    wire            [ 7:0]      matrix_32           ;
    wire            [ 7:0]      matrix_33           ;
        
    reg             [ 9:0]      RGB888_R            ;
    reg             [ 9:0]      RGB888_G            ;
    reg             [ 9:0]      RGB888_B            ;
        
    reg             [11:0]      row_cnt             ;   //  行计数器
    reg             [11:0]      col_cnt             ;   //  列计数器
        
    reg             [ 1:0]      bayer_de_r          ;
    reg             [ 1:0]      bayer_hsync_r       ;
    reg             [ 1:0]      bayer_vsync_r       ;

    wire                        vsync_pos           ;

// 对齐矩阵耗费1clk
matrix_3x3_8bit
#(
    .H_DISP                     (H_DISP             ),
    .V_DISP                     (V_DISP             )
)   
u_matrix_3x3_8bit   
(   
    .clk                        (clk                ),
    .rst_n                      (rst_n              ),
    .din_vld                    (bayer_de           ),
    .din                        (bayer_data         ),

    .matrix_11                  (matrix_11          ),
    .matrix_12                  (matrix_12          ),
    .matrix_13                  (matrix_13          ),
    .matrix_21                  (matrix_21          ),
    .matrix_22                  (matrix_22          ),
    .matrix_23                  (matrix_23          ),
    .matrix_31                  (matrix_31          ),
    .matrix_32                  (matrix_32          ),
    .matrix_33                  (matrix_33          )
);

/***********************************************************/
// 行列计数，用于像素位置编码
// 行计数
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        row_cnt <= 12'd0;
    else if(bayer_de_r[0])
        if(row_cnt == H_DISP-1)
            row_cnt <= 12'd0;
        else
            row_cnt <= row_cnt+ 1;
    else
        row_cnt <= row_cnt;  
end

// 列计数
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        col_cnt <= 12'd0;        
    else if(row_cnt == H_DISP-1 && bayer_de_r[0])
        col_cnt <= col_cnt+ 1;
    else
        col_cnt <= col_cnt;   
end
/***********************************************************/

/***********************************************************/
// Demoasaic
// 以下代码以GRBG形式的拜尔阵列进行双线性插值
// 像素阵列示意如下
// G R G R G R G R G R G R
// B G B G B G B G B G B G
// G R G R G R G R G R G R
// B G B G B G B G B G B G
// G R G R G R G R G R G R
// B G B G B G B G B G B G
// 以四个像素为一组进行编码，对应遍历像素时的四种情况，如下
// 00 01 00 01 00 01 00 01
// 10 11 10 11 10 11 10 11
// 00 01 00 01 00 01 00 01
// 10 11 10 11 10 11 10 11
// 00 01 00 01 00 01 00 01
// 10 11 10 11 10 11 10 11
//always @(posedge clk or negedge rst_n) begin
//    if(!rst_n)
//        begin
//            RGB888_R <= 10'b0;
//            RGB888_G <= 10'b0;
//            RGB888_B <= 10'b0;
//        end
//    else
//        case({col_cnt[0],row_cnt[0]})
//            2'b00:  // 绿色中心，红色在水平方向，蓝色在垂直方向
//            begin
//                RGB888_R <= (matrix_21 + matrix_23) >> 1;
//                RGB888_G <= matrix_22;
//                RGB888_B <= (matrix_12 + matrix_32) >> 1;
//            end    
//            2'b01:  // 红色中心，蓝色在对角线方向，绿色在水平垂直方向
//            begin
//                RGB888_R <= matrix_22;
//                RGB888_G <= (matrix_12 + matrix_21 + matrix_23 + matrix_32) >> 2;
//                RGB888_B <= (matrix_11 + matrix_13 + matrix_31 + matrix_33) >> 2;
//            end  
//            2'b10:  // 蓝色中心，红色在对角线方向，绿色在水平垂直方向
//            begin
//                RGB888_R <= (matrix_11 + matrix_13 + matrix_31 + matrix_33) >> 2;
//                RGB888_G <= (matrix_12 + matrix_21 + matrix_23 + matrix_32) >> 2;
//                RGB888_B <= matrix_22;
//            end
//            2'b11:  // 绿色中心，红色在垂直方向，蓝色在水平方向
//            begin
//                RGB888_R <= (matrix_12 + matrix_32) >> 1;
//                RGB888_G <= matrix_22;
//                RGB888_B <= (matrix_21 + matrix_23) >> 1;
//            end                                                                
//            default:
//            begin
//                RGB888_R <= 10'b0;
//                RGB888_G <= 10'b0;
//                RGB888_B <= 10'b0;
//            end
//        endcase
//end

// RGGB像素阵列示意如下
// R G R G R G R G R G R G
// G B G B G B G B G B G B
// R G R G R G R G R G R G
// G B G B G B G B G B G B
// R G R G R G R G R G R G
// G B G B G B G B G B G B
// 以四个像素为一组进行编码，对应遍历像素时的四种情况，如下
// 00 01 00 01 00 01 00 01
// 10 11 10 11 10 11 10 11
// 00 01 00 01 00 01 00 01
// 10 11 10 11 10 11 10 11
// 00 01 00 01 00 01 00 01
// 10 11 10 11 10 11 10 11
//always @(posedge clk or negedge rst_n) begin
//    if(!rst_n)
//        begin
//            RGB888_R <= 10'b0;
//            RGB888_G <= 10'b0;
//            RGB888_B <= 10'b0;
//        end
//    else
//        case({col_cnt[0],row_cnt[0]})
//            2'b01:  // 绿色中心，红色在水平方向，蓝色在垂直方向
//            begin
//                RGB888_R <= (matrix_21 + matrix_23) >> 1;
//                RGB888_G <= matrix_22;
//                RGB888_B <= (matrix_12 + matrix_32) >> 1;
//            end    
//            2'b00:  // 红色中心，蓝色在对角线方向，绿色在水平垂直方向
//            begin
//                RGB888_R <= matrix_22;
//                RGB888_G <= (matrix_12 + matrix_21 + matrix_23 + matrix_32) >> 2;
//                RGB888_B <= (matrix_11 + matrix_13 + matrix_31 + matrix_33) >> 2;
//            end  
//            2'b11:  // 蓝色中心，红色在对角线方向，绿色在水平垂直方向
//            begin
//                RGB888_R <= (matrix_11 + matrix_13 + matrix_31 + matrix_33) >> 2;
//                RGB888_G <= (matrix_12 + matrix_21 + matrix_23 + matrix_32) >> 2;
//                RGB888_B <= matrix_22;
//            end
//            2'b10:  // 绿色中心，红色在垂直方向，蓝色在水平方向
//            begin
//                RGB888_R <= (matrix_12 + matrix_32)>>1;
//                RGB888_G <= matrix_22;
//                RGB888_B <= (matrix_21 + matrix_23)>>1;
//            end                                                                
//            default:
//            begin
//                RGB888_R <= 10'b0;
//                RGB888_G <= 10'b0;
//                RGB888_B <= 10'b0;
//            end
//        endcase
//end

// BGGR像素阵列示意如下
// B G B G B G B G B G B G
// G R G R G R G R G R G R
// B G B G B G B G B G B G
// G R G R G R G R G R G R
// B G B G B G B G B G B G
// G R G R G R G R G R G R
// 以四个像素为一组进行编码，对应遍历像素时的四种情况，如下
// 00 01 00 01 00 01 00 01
// 10 11 10 11 10 11 10 11
// 00 01 00 01 00 01 00 01
// 10 11 10 11 10 11 10 11
// 00 01 00 01 00 01 00 01
// 10 11 10 11 10 11 10 11
//always @(posedge clk or negedge rst_n) begin
//    if(!rst_n)
//        begin
//            RGB888_R <= 10'b0;
//            RGB888_G <= 10'b0;
//            RGB888_B <= 10'b0;
//        end
//    else
//        case({col_cnt[0],row_cnt[0]})
//            2'b00:  // 绿色中心，红色在水平方向，蓝色在垂直方向
//            begin
//                RGB888_R <= (matrix_21 + matrix_23) >> 1;
//                RGB888_G <= matrix_22;
//                RGB888_B <= (matrix_12 + matrix_32) >> 1;
//            end    
//            2'b01:  // 绿色中心，红色在垂直方向，蓝色在水平方向
//            begin
//                RGB888_R <= (matrix_12 + matrix_32)>>1;
//                RGB888_G <= matrix_22;
//                RGB888_B <= (matrix_21 + matrix_23)>>1;
//            end 
//            2'b10:  // 绿色中心，红色在水平方向，蓝色在垂直方向
//            begin
//                RGB888_R <= (matrix_21 + matrix_23) >> 1;
//                RGB888_G <= matrix_22;
//                RGB888_B <= (matrix_12 + matrix_32) >> 1;
//            end 
//            2'b11:  // 红色中心，蓝色在对角线方向，绿色在水平垂直方向
//            begin
//                RGB888_R <= matrix_22;
//                RGB888_G <= (matrix_12 + matrix_21 + matrix_23 + matrix_32) >> 2;
//                RGB888_B <= (matrix_11 + matrix_13 + matrix_31 + matrix_33) >> 2;
//            end                                                    
//            default:
//            begin
//                RGB888_R <= 10'b0;
//                RGB888_G <= 10'b0;
//                RGB888_B <= 10'b0;
//            end
//        endcase
//end

// GBRG像素阵列示意如下
// G B G B G B G B G B G B
// R G R G R G R G R G R G
// G B G B G B G B G B G B
// R G R G R G R G R G R G
// G B G B G B G B G B G B
// R G R G R G R G R G R G
// 以四个像素为一组进行编码，对应遍历像素时的四种情况，如下
// 00 01 00 01 00 01 00 01
// 10 11 10 11 10 11 10 11
// 00 01 00 01 00 01 00 01
// 10 11 10 11 10 11 10 11
// 00 01 00 01 00 01 00 01
// 10 11 10 11 10 11 10 11
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        begin
            RGB888_R <= 10'b0;
            RGB888_G <= 10'b0;
            RGB888_B <= 10'b0;
        end
    else
        case({col_cnt[0],row_cnt[0]})  
            2'b00:  // 绿色中心，红色在垂直方向，蓝色在水平方向
            begin
                RGB888_R <= (matrix_12 + matrix_32)>>1;
                RGB888_G <= matrix_22;
                RGB888_B <= (matrix_21 + matrix_23)>>1;
            end 
            2'b01:  // 蓝色中心，红色在对角线方向，绿色在水平垂直方向
            begin
                RGB888_R <= (matrix_11 + matrix_13 + matrix_31 + matrix_33) >> 2;
                RGB888_G <= (matrix_12 + matrix_21 + matrix_23 + matrix_32) >> 2;
                RGB888_B <= matrix_22;
            end 
            2'b10:  // 红色中心，蓝色在对角线方向，绿色在水平垂直方向
            begin
                RGB888_R <= matrix_22;
                RGB888_G <= (matrix_12 + matrix_21 + matrix_23 + matrix_32) >> 2;
                RGB888_B <= (matrix_11 + matrix_13 + matrix_31 + matrix_33) >> 2;
            end  
            2'b11:  // 绿色中心，红色在水平方向，蓝色在垂直方向
            begin
                RGB888_R <= (matrix_21 + matrix_23) >> 1;
                RGB888_G <= matrix_22;
                RGB888_B <= (matrix_12 + matrix_32) >> 1;
            end                                                
            default:
            begin
                RGB888_R <= 10'b0;
                RGB888_G <= 10'b0;
                RGB888_B <= 10'b0;
            end
        endcase
end
/***********************************************************/

/***********************************************************/
//  信号同步
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        bayer_de_r    <= 2'b0;
        bayer_hsync_r <= 2'b0;
        bayer_vsync_r <= 2'b0;
    end
    else begin  
        bayer_de_r    <= {bayer_de_r   [0],    bayer_de};
        bayer_hsync_r <= {bayer_hsync_r[0], bayer_hsync};
        bayer_vsync_r <= {bayer_vsync_r[0], bayer_vsync};
    end
end

assign vsync_pos = bayer_vsync_r[0] & (~bayer_vsync_r[1]);
/***********************************************************/

/***********************************************************/
//  信号输出
assign RGB888_hsync = bayer_hsync_r[1];
assign RGB888_vsync = bayer_vsync_r[1];
assign RGB888_data  = {RGB888_R[7:0] , RGB888_G[7:0] , RGB888_B[7:0]};
assign RGB888_de    = bayer_de_r[1];
/***********************************************************/

endmodule