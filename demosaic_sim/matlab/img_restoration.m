clear all;
close all;
clc;

origin_img = imread('origin.png');
bayer_img = imread('bayer_GBRG.png');
[v,h,N] = size(origin_img);
processed_img = uint8(zeros(v,h,N));

fid = fopen('RGB888_img.txt','r');
for i = 1:v
    for j = 1:h
        value = fscanf(fid,'%s',1);
        processed_img(i,j,1) = uint8(hex2dec(value(1:2)));
        processed_img(i,j,2) = uint8(hex2dec(value(3:4)));
        processed_img(i,j,3) = uint8(hex2dec(value(5:6)));  
    end 
end
fclose(fid);                                    

subplot(131);imshow(origin_img), title('Origin');
subplot(132);imshow(bayer_img), title('Bayer');
subplot(133);imshow(processed_img),title('After Demosaic');

imwrite(processed_img,'RGB888.jpg');