#' split_image
#'
#' split_image splits a large image into small ones at a predefined size
#'
#' @param image a character value representing the path to the image file
#' @param split_dir a character value representing the directory to save the split images
#' @param w an integer value representing the width of the split images
#' @param h an integer value representing the height of the split images
#' @param margin an integer value representing the margin of one split image overlapping with others 
#' @param x_scale a numeric value from 0 to 1 for resizing the image
#' @param spot_coordinates a data frame of spot coordiantes with row representing the spot and column representing the X and Y coordinates
#' @param rgbscale a boolean value indicating whether to write out split images in RGB scale
#' @param grayscale a boolean value indicating whether to write out split images in grey scale. If rgbscale==FALSE and grayscale==FALSE, then output the split images in original scale
#' 
#' @author Shijia Zhu, \email{shijia.zhu@@utsouthwestern.edu}
#' @export
#'
#' @references
#'
#' @seealso \code{\link{merge_feature}}; \code{\link{run_imageJ_plugin}};
#' 
#' 
split_image <- function(image, split_dir, w=3000, h=3000, margin=100, 
                      x_scale=1, spot_coordinates=NULL, 
                      rgbscale=FALSE, grayscale=FALSE, layer=1) {
    
    cat("Reading", image, "...\n")
    dir.create(split_dir, recursive = T)
    
    im <- image_read(path = image)
    im <- im[layer]
    
    iminf <- image_info(im)
    width <- iminf$width
    height <- iminf$height
    
    w_num <- ceiling(width/w)
    h_num <- ceiling(height/h)
        
    for( i in 1:w_num ) {
        
        for(j in 1:h_num) {
            
            xoff_ij <- w*(i-1)+1
            yoff_ij <- h*(j-1)+1
            
            w_ij <- w+margin
            h_ij <- h+margin
            
            cat(i, "and", j, "->  xoff:", xoff_ij, "yoff:", yoff_ij,
                "w:", w_ij, "h:", h_ij, "...\n")
            
            if( is.null(spot_coordinates) ) {
                spot_covered = TRUE
            } else {
                mm = w_ij*0.1
                spot_covered = any( mapply( function(x,y) 
                                            (xoff_ij-mm) <= x & (xoff_ij+w_ij+mm) >= x & (yoff_ij-mm) <= y & (yoff_ij+h_ij+mm) >= y , 
                                            as.integer(spot_coordinates$X), as.integer(spot_coordinates$Y) ) )
            }
            
            if(spot_covered)
            {
                split_im <- im %>%
                    image_crop(geometry = geometry_area(width = w_ij, height = h_ij, x_off = xoff_ij, y_off = yoff_ij))
                
                if (x_scale<1) {
                    split_iminf <- image_info(split_im)
                    split_im <- split_im %>%
                        image_scale(paste0(round(x_scale*split_iminf$width))) 
                }
                
                fext <- tools::file_ext(image)
                
                if(!grayscale & !rgbscale) 
                {
                    outpath <- paste0(split_dir, "/split_im_w_",w_ij,"_h_",h_ij,"_xoff_",xoff_ij,"_yoff_",yoff_ij,".",fext)
                    magick::image_write(split_im, path = outpath, format = fext)
                }
                
                if(grayscale & !rgbscale) 
                {
                    ebi_im <- as_EBImage(split_im)
                    imrb <- EBImage::rgbImage(red = EBImage::channel(ebi_im, "red"), blue = EBImage::channel(ebi_im, "blue"))
                    imgray <- EBImage::channel(imrb, "gray")
                    imgray <- 1 - imgray
                    imgray <- imgray^2
                    filegray <- paste0(split_dir, "/split_im_w_",w_ij,"_h_",h_ij,"_xoff_",xoff_ij,"_yoff_",yoff_ij,"_grayscale.",fext)
                    EBImage::writeImage(x=imgray, type=fext, files=filegray, quality = 100)
                }
                
                if(rgbscale & !grayscale) 
                {
                    ebi_im <- as_EBImage(split_im)
                    imrgb <- EBImage::rgbImage(red = EBImage::channel(ebi_im, "red"), 
                                               green = EBImage::channel(ebi_im, "green"), 
                                               blue = EBImage::channel(ebi_im, "blue"))
                    filergb <- paste0(split_dir, "/split_im_w_",w_ij,"_h_",h_ij,"_xoff_",xoff_ij,"_yoff_",yoff_ij,"_rgbscale.",fext)
                    EBImage::writeImage(x=imrgb, type=fext, files=filergb, quality = 100)
                }
                
            }
            
        }
    }
}


