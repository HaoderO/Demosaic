close all;
clear;
clc

%read img,get hang,lie,weidu

    H = imread('origin.png');
    A = double(H);
    [hang,lie,wei]=size(A);%2160,3840,3

%   G R B G     

    GRBG=zeros(hang,lie);     
    for i=1:2:hang             %G
        for j=1:2:lie          
            GRBG(i,j)=A(i,j,2);
        end 
    end

    for i=1:2:hang      %2160   R
        for j=2:2:lie   %3840   
            GRBG(i,j)=A(i,j,1);
        end 
    end
    for i=2:2:hang              %B
        for j=1:2:lie      
            GRBG(i,j)=A(i,j,3);
        end 
    end
    for i=2:2:hang              %G
        for j=2:2:lie      
            GRBG(i,j)=A(i,j,2);
        end 
    end

C1=uint8(GRBG);

imwrite(C1,'bayer_GRBG.png');
fid=fopen('bayer_GRBG.txt','w');
for i=1:hang  
    for j=1:lie
        fprintf(fid,'%x\n',C1(i,j));
    end   
end
fclose(fid); 

%csvwrite('bayer_GRBG.txt',C1)

%   R G G B

    RGGB=zeros(hang,lie);
    for i=1:2:hang      %2160   R
        for j=1:2:lie   %3840   
            RGGB(i,j)=A(i,j,1);    
        end 
    end
    for i=1:2:hang             %G
        for j=2:2:lie      
            RGGB(i,j)=A(i,j,2);    
        end 
    end
    for i=2:2:hang              %G
        for j=1:2:lie      
            RGGB(i,j)=A(i,j,2);    
        end 
    end
    for i=2:2:hang              %B
        for j=2:2:lie      
            RGGB(i,j)=A(i,j,3);    
        end 
    end

C2=uint8(RGGB);
imwrite(C2,'bayer_RGGB.png');
fid=fopen('bayer_RGGB.txt','w');
for i=1:hang  
    for j=1:lie
        fprintf(fid,'%x\n',C2(i,j));
    end   
end
fclose(fid); 

%csvwrite('bayer_RGGB.txt',C2)

%   B G G R
    BGGR=zeros(hang,lie);
    for i=1:2:hang              %B
        for j=1:2:lie      
            BGGR(i,j)=A(i,j,3);    
        end 
    end
    for i=1:2:hang             %G
        for j=2:2:lie      
            BGGR(i,j)=A(i,j,2);    
        end 
    end
    for i=2:2:hang              %G
        for j=1:2:lie      
            BGGR(i,j)=A(i,j,2);    
        end 
    end
    for i=2:2:hang      %3840   R
        for j=2:2:lie   %2160   
            BGGR(i,j)=A(i,j,1);    
        end 
    end

C3=uint8(BGGR);
imwrite(C3,'bayer_BGGR.png');
fid=fopen('bayer_BGGR.txt','w');
for i=1:hang  
    for j=1:lie
        fprintf(fid,'%x\n',C3(i,j));
    end   
end
fclose(fid); 

%csvwrite('bayer_BGGR.txt',C3)

%   G B R G
    GBRG=zeros(hang,lie);
    for i=1:2:hang             %G
        for j=1:2:lie      
            GBRG(i,j)=A(i,j,2);    
        end 
    end
    for i=1:2:hang              %B
        for j=2:2:lie      
            GBRG(i,j)=A(i,j,3);    
        end 
    end
    for i=2:2:hang      %3840   R
        for j=1:2:lie   %2160   
            GBRG(i,j)=A(i,j,1);    
        end 
    end
    for i=2:2:hang              %G
        for j=2:2:lie      
            GBRG(i,j)=A(i,j,2);    
        end 
    end
C4=uint8(GBRG);
imwrite(C4,'bayer_GBRG.png');
fid=fopen('bayer_GBRG.txt','w');
for i=1:hang  
    for j=1:lie
        fprintf(fid,'%x\n',C4(i,j));
    end   
end
fclose(fid); 
%csvwrite('bayer_GBRG.txt',C4)

subplot(231),imshow(H);
subplot(232),imshow(C1);
subplot(233),imshow(C2);
subplot(234),imshow(C3);
subplot(235),imshow(C4);