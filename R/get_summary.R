#' getSummary
#'
#' getSummary calculates the scores for the STIE result
#' 
#' @param STIE_result a list generated by the STIE() function
#' @param ST_expr a matrix of spot level gene expression with row representing the spot and column representing the gene
#'
#' @return A list containing the follow components:
#' \itemize{
#'  \item {rmse} a vector of numeric values representing RMSE for each spot
#'  \item {mse} a data frame representing the cells on spots along with the cellular morphological features, which is the same data frame cells_on_spot with the input
#'  \item {LL_Morp} a vector of numeric values representing RMSE for each spot
#'  \item {LL_Expr} a data frame representing the cells on spots along with the cellular morphological features, which is the same data frame cells_on_spot with the input
#'  \item {logLik} a data frame representing the cells on spots along with the cellular morphological features, which is the same data frame cells_on_spot with the input
#'  \item {EM_diff2} a numeric value representing difference between morphology and expression-based estimation
#'  \item {L2_sum} a numeric value representing MSE + lambda*EM_diff2
#' }
#' 
#' @author Shijia Zhu, \email{shijia.zhu@@utsouthwestern.edu}
#'
#' @references
#' @export
#'
#' @seealso \code{\link{STIE}}; 
#' 
#' 
get_summary <- function(STIE_result, ST_expr)
{
    cells_on_spot = STIE_result$cells_on_spot
    spot_id = as.character(cells_on_spot$spot)
    cell_id = as.character(cells_on_spot$cell_id)
    
    Signature = STIE_result$Signature
    cell_types = STIE_result$cell_types
    mu = STIE_result$mu
    sigma = STIE_result$sigma
    features = colnames(mu)
    #######################
    PM_on_cell = STIE_result$PM_on_cell
    PE_on_spot = STIE_result$PE_on_spot
    uni_spot_id = rownames(PE_on_spot)
    
    PE_on_cell = PE_on_spot[ spot_id, ]
    rownames(PE_on_cell) = cell_id
    
    PM_on_spot = apply(PM_on_cell, 2, function(x) tapply(x,spot_id,sum) )
    PM_on_spot = t( apply( PM_on_spot, 1, function(x) x/sum(x) ) )
    PM_on_spot = PM_on_spot[ uni_spot_id, ]
    
    PME_on_cell = t( apply(PM_on_cell*PE_on_cell,1,function(x)x/sum(x)) )
    PME_on_spot = apply( PME_on_cell, 2, function(x) tapply(x,spot_id,sum) )
    PME_on_spot = PME_on_spot[uni_spot_id, ]
    
    #######################
    lambdas = rep(STIE_result$lambda,nrow(PE_on_spot))
    Expr_on_spot = ST_expr[ uni_spot_id, match(rownames(Signature),colnames(ST_expr)) ]
    
    #######################
    celltypes_on_spot = table(spot_id, cell_types)
    if( ncol(celltypes_on_spot) < ncol(Signature) )
    {
        missed = setdiff( colnames(Signature), colnames(celltypes_on_spot)  )
        tmp = matrix(nrow=nrow(celltypes_on_spot), ncol=length(missed),data=0)
        colnames(tmp) = missed
        celltypes_on_spot = cbind(celltypes_on_spot, tmp ) 
    }
    celltypes_on_spot = celltypes_on_spot[uni_spot_id, colnames(PM_on_spot)]
    #celltypes_on_spot = t(apply(celltypes_on_spot,1,function(x)x/sum(x)))
    
    #################################################################################
    ######### claim two functions
    #################################################################################
    solveOLS2 <- function(Signature, Expr_on_spot_i, 
                          PE_on_spot_i, PM_on_spot_i, 
                          lambda, scaled=T) {
        
        # Signature is the matrix of cell type signature
        # Expr_on_spot_i is the gene expression of i-th spot
        # PE_on_spot_i is the current estimation of regression coefficients
        # PM_on_spot_i is the probability of morphology for cell type
        # lambda is the langurange multiplier
        
        t <- ncol(Signature)
        I <- diag(t)
        
        D <- t(Signature)%*%Signature + lambda*I
        d <- t(Signature)%*%Expr_on_spot_i + lambda*sum(PE_on_spot_i)*I%*%PM_on_spot_i
        A <- I
        bzero <- c(rep(0,t))
        solution <- solve.QP(D,d,A)$solution
        names(solution) <- colnames(Signature)
        
        solution[solution<0] = 1e-100
        
        if(scaled) solution <- solution/sum(solution)
        solution
    }
    
    calculate_residues = function(B, X=Signature, Y=Expr_on_spot) {
        lapply(1:nrow(Y), function(i) {
            y = as.numeric(Y[i,])
            b = as.numeric(B[i,])
            bx = X%*%b
            t = sum(y)/sum(bx)
            y-t*bx
        } )
    }
    
    #################################################################################
    ######### RMSE
    #################################################################################
    
    residuals = calculate_residues(B=celltypes_on_spot, X=Signature, Y=Expr_on_spot)
    names(residuals) = rownames(Expr_on_spot)
    mse = sapply( residuals, function(r) mean(r^2) )
    #mse = sapply( residuals, function(r) sum(r^2) )
    rmse = mean(sqrt(mse))
    
    #################################################################################
    ######### logLik
    #################################################################################
    PM_on_cell_unscaled = calculate_morphology_probability(cells_on_spot, features, mu, sigma, scale=F )
    PME_on_cell_unscaled = PM_on_cell_unscaled * PE_on_cell
    #PME_on_cell_unscaled = PM_on_cell_unscaled
    
    LL_Expr = sapply(residuals, function(r) {
        ll = log(dnorm(r,sd=sd(r)))
        ll[is.infinite(ll)] = min(ll[!is.infinite(ll)])
        mean(ll)
    })
    names(LL_Expr) = uni_spot_id
    LL_Expr = LL_Expr[spot_id]
    
    #LL_Morp = log(rowSums(PME_on_cell_unscaled))
    LL_Morp = log(rowSums(PME_on_cell_unscaled))/ncol(mu)
    logLik = sum(LL_Expr) + sum(LL_Morp)
    
    #################################################################################
    ######### Q function
    #################################################################################
    if(0) {
        Qfunc_morph <- PME_on_cell*log(PM_on_cell)
        names(Qfunc_morph) = rownames(PM_on_cell)
        
        Qfunc_expr = sapply( 1:nrow(Expr_on_spot), function(i) {
            Expr_on_spot_i = as.numeric( Expr_on_spot[i,] )
            PE_on_spot_i = PE_on_spot[i,]
            PM_on_spot_i = PM_on_spot[i,]
            PME_on_spot_i = PME_on_spot[i,]
            PME_on_spot_i = PM_on_spot[i,]
            lai = lambdas[i]
            
            beta = solveOLS2(Signature, Expr_on_spot_i, PE_on_spot_i, PM_on_spot_i, 
                             lambda = lai, scaled=FALSE)
            
            S = sum(beta)
            loss1 <- -sum( (Expr_on_spot_i - Signature %*% beta)^2 )/(2*sum(PME_on_spot_i))
            loss2 <- t(PME_on_spot_i) %*% log(beta/S+1e-100) 
            loss3 <- lai * sum((PE_on_spot_i - PM_on_spot_i )^2)
            loss1 + loss3
        })
        names(Qfunc_expr) = uni_spot_id
        
        Qfunc <- sum(Qfunc_morph) + sum(Qfunc_expr)
    }
    
    #################################################################################
    ######### L2 norm
    #################################################################################
    
    q_theta = colSums(PME_on_cell)/sum(PME_on_cell)
    q_theta = q_theta[colnames(PM_on_spot)]
    PqM_on_spot = t(apply(PM_on_spot,1,function(x) (x*q_theta)/sum(x*q_theta) ))
    
    EM_diff2 = sum( (PqM_on_spot - PE_on_spot)^2)
    MSE_sum2 = sum(sapply( residuals, function(r) sum(r^2) ))
    L2_sum = MSE_sum2 + STIE_result$lambda * EM_diff2
    
    MSE_sum2_spot = sapply( residuals, function(r) sum(r^2) )
    EM_diff2_spot = rowSums( (PqM_on_spot - PE_on_spot)^2 )
    L2_sum_spot = MSE_sum2_spot + STIE_result$lambda * EM_diff2_spot
    
    
    list( mse=mse, rmse=rmse, 
          logLik_Morp=LL_Morp, logLik_Expr=LL_Expr, logLik=logLik, 
          EMdiff2=EM_diff2, MSEsum2=MSE_sum2, L2sum=L2_sum )
    #Qfuc_Morp=sum(Qfunc_morph), Qfuc_Expr=sum(Qfunc_expr), Qfunc=Qfunc,
    
    
}

