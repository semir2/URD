#' Plot 2D Dendrogram of URD Tree
#' 
#' @import ggplot2
#' @importFrom stats aggregate
#' 
#' @param object An URD object
#' @param label (Character) Data to use for color information, see \link{data.for.plot}
#' @param label.type (Character) See \link{data.for.plot}
#' @param title (Character) Title to display on the plot
#' @param legend (Logical) Show a legend?
#' @param legend.title (Character) Title to display on the legend
#' @param legend.point.size (Numeric) How big should points be in the legend?
#' @param plot.tree (Logical) Whether to plot the dendrogram
#' @param tree.alpha (Numeric) Transparency of dendrogram (0 is transparent, 1 is opaque)
#' @param tree.size (Numeric) Thickness of lines of dendrogram
#' @param plot.tree (Logical) Whether cells should be plotted with the tree
#' @param cell.alpha (Numeric) Transparency of cells (0 is transparent, 1 is opaque)
#' @param cell.size (Numeric) How large should cells be
#' @param label.x (Logical) Should tips on the x-axis be labeled
#' @param label.segments (Logical) Should segments of the dendrogram be labeled with their numbers
#' @param discrete.ignore.na (Logical)
#' @param color.tree (Logical) Should the dendrogram be colored according to the data? Default \code{NULL} colors the tree when plotting continuous variables, but not when plotting discrete variables.
#' @param continuous.colors (Character vector) Colors to make color scale if plotting a continuous variable
#' @param discrete.colors (Character vector) Colors to use if plotting a discrete variable
#' @param color.limits (Numeric vector, length 2) Minimum and maximum values for color scale. Default \code{NULL} auto-detects.
#' @param symmetric.color.scale (Logical) Should the color scale be symmetric and centered around 0? (Default \code{NULL} is \code{FALSE} if all values are positive, and \code{TRUE} if both positive and negative values are present.)
#' @param hide.y.ticks (Logical) Should the pseudotime values on the y-axis be hidden?
#' 
#' @return A ggplot2 object
#' 
#' @export
plotTree <- function(object, label=NULL, label.type="search", title=label, legend=T, legend.title="", legend.point.size=6*cell.size, plot.tree=T, tree.alpha=1, tree.size=1, plot.cells=T, cell.alpha=0.25, cell.size=0.5, label.x=T, label.segments=F, discrete.ignore.na=F, color.tree=NULL, continuous.colors=NULL, discrete.colors=NULL, color.limits=NULL, symmetric.color.scale=NULL, hide.y.ticks=T) {
  
  # Grab various layouts from the object
  segment.layout <- object@tree$segment.layout
  tree.layout <- object@tree$tree.layout
  if (plot.cells) cell.layout <- object@tree$cell.layout

  # Initialize ggplot and do basic formatting
  the.plot <- ggplot()
  if (hide.y.ticks) {
    the.plot <- the.plot + scale_y_reverse(c(1,0), name="Pseudotime", breaks=NULL)
  } else {
    the.plot <- the.plot + scale_y_reverse(c(1,0), name="Pseudotime", breaks=seq(0, 1, 0.1))
  }
  the.plot <- the.plot + theme_bw() + theme(axis.ticks=element_blank(), panel.grid.major=element_blank(), panel.grid.minor=element_blank())
  the.plot <- the.plot + labs(x="", title=title, color=legend.title)
  
  # Extract expression information
  if (!is.null(label)) {
    # Grab data to color by
    if (length(label) > 1) stop("Cannot plot by multiple labels simultaneously.")
    color.data <- data.for.plot(object, label=label, label.type=label.type, as.color=F, as.discrete.list = T, cells.use=rownames(object@diff.data))
    color.discrete <- color.data$discrete
    color.data <- data.frame(cell=names(color.data$data), value=color.data$data, node=object@diff.data[,"node"], stringsAsFactors=F)
  }
  
  # Summarize expression information if plotting tree
  if (plot.tree && !is.null(label)) {
    if (!color.discrete) {
      # Mean expression per node
      node.data <- aggregate(color.data$value, by=list(color.data$node), FUN=mean.of.logs)
      rownames(node.data) <- node.data$Group.1
      node.data$n <- unlist(lapply(object@tree$cells.in.nodes, length))[node.data$Group.1]
    } else {
      # If uniform expression, then give that output, otherwise give NA.
      node.data <- aggregate(color.data$value, by=list(color.data$node), FUN=output.uniform, na.rm=discrete.ignore.na)
      rownames(node.data) <- node.data$Group.1
      node.data$n <- unlist(lapply(object@tree$cells.in.nodes, length))[node.data$Group.1]
    }
    
    # Color segments according to their expression of their end node
    # (Replace -0 nodes with -1 for getting expression data.)
    tree.layout$node.1 <- gsub("-0","-1",tree.layout$node.1)
    tree.layout$node.2 <- gsub("-0","-1",tree.layout$node.2)
    tree.layout[,"expression"] <- node.data[tree.layout$node.2,"x"]
  }  
  
  # Figure out color limits if plotting a non-discrete label
  if (!is.null(label) && !color.discrete && is.null(color.limits)) {
    # Take from cells if plotting, otherwise from tree.
    if (plot.cells) color.data.for.scale <- color.data$value else color.data.for.scale <- tree.layout$expression
    # Set symmetric scale automatically if not provided
    if (is.null(symmetric.color.scale)) {
      if (min(color.data.for.scale) < 0) symmetric.color.scale <- T else symmetric.color.scale <- F
    }
    if (symmetric.color.scale) {
      color.mv <- max(abs(color.data.for.scale))
      color.limits <- c(-1*color.mv, color.mv)
    } else {
      color.max <- max(color.data.for.scale)
      color.min <- min(c(0, color.data.for.scale))
      color.limits <- c(color.min, color.max)
    }
  }
  
  # Add cells to graph
  if (plot.cells) {
    if (!is.null(label)) {
      # Add color info to cell.layout
      if (color.discrete) {
        cell.layout$expression <- as.factor(color.data[cell.layout$cell, "value"])
      } else {
        cell.layout$expression <- color.data[cell.layout$cell, "value"]
      }
      # With color
      the.plot <- the.plot + geom_point(data=cell.layout, aes(x=x,y=y,color=expression), alpha=cell.alpha, size=cell.size)
    } else {
      # Just plain black if no label
      the.plot <- the.plot + geom_point(data=cell.layout, aes(x=x,y=y), alpha=cell.alpha, size=cell.size)
    }
  }
  
  # If color.tree is NULL, determine what it should be.
  if (is.null(label)) {
    color.tree <- FALSE
  } else if (is.null(color.tree)) {
    if (color.discrete) color.tree <- F else color.tree <- T
  }
  
  # Add tree to graph
  if (plot.tree) {
    if (!is.null(label) && color.tree) {
      # With color, if desired
      the.plot <- the.plot + geom_segment(data=tree.layout, aes(x=x1, y=y1, xend=x2, yend=y2, color=expression), alpha=tree.alpha, size=tree.size, lineend="square") 
    } else {
      # Just plain black if no label
      the.plot <- the.plot + geom_segment(data=tree.layout, aes(x=x1, y=y1, xend=x2, yend=y2), color='black', alpha=tree.alpha, size=tree.size, lineend="square")
    }
  }
  
  # Add color
  if (!is.null(label)) {
    if (!color.discrete) {
      if (is.null(continuous.colors)) {
        the.plot <- the.plot + scale_color_gradientn(colors=defaultURDContinuousColors(with.grey=T, symmetric=symmetric.color.scale), limits=color.limits)
      } else {
        the.plot <- the.plot + scale_color_gradientn(colors=continuous.colors, limits=color.limits)
      }
    } else {
      if (!is.null(discrete.colors)) {
        the.plot <- the.plot + scale_color_manual(values=discrete.colors)
      }
    }
  }
  
  # Remove legend if desired
  if (!legend) {
    the.plot <- the.plot + guides(color=FALSE, shape=FALSE)
  } else if (!is.null(label) && color.discrete) {
    # Otherwise, make the legend points bigger if coloring by a discrete value
    the.plot <- the.plot + guides(color=guide_legend(override.aes = list(size=legend.point.size, alpha=1)))
  }
  
  # Label segment names along the x-axis?
  if (label.x) {
    if ("segment.names" %in% names(object@tree)) {
      # Add segment names to segment.layout
      segment.layout$name <- object@tree$segment.names[segment.layout$segment]
      tip.layout <- segment.layout[complete.cases(segment.layout),]
    } else {
      # Find terminal tips
      tip.layout <- segment.layout[which(segment.layout$segment %in% object@tree$tips),]
      tip.layout$name <- as.character(tip.layout$segment)
    }
    the.plot <- the.plot + scale_x_continuous(breaks=as.numeric(tip.layout$x), labels=as.character(tip.layout$name))
    if (any(unlist(lapply(tip.layout$name, nchar)) > 2)) {
      the.plot <- the.plot + theme(axis.text.x = element_text(angle = 68, vjust = 1, hjust=1))
    }
  } else {
    the.plot <- the.plot + theme(axis.text.x=element_blank())
  }
  
  # Label the segments with their number?
  if (label.segments) {
    segment.labels <- as.data.frame(segment.layout[,c("segment","x")])
    segment.labels$y <- apply(object@tree$segment.pseudotime.limits, 1, num.mean)[segment.labels$segment]
    the.plot <- the.plot + geom_label(data=segment.labels, aes(x=x, y=y, label=segment), alpha=0.5)
  }
  
  return(the.plot)
}

#' Is Vector Uniform?
#' 
#' Determine whether all elements of a vector are the same
#' 
#' @param x (Vector) Values to check for uniformity
#' @param na.rm (Logical) Should NA be considered a value or excluded from the comparison?
#' 
#' @return Either \code{NA} if the vector is not uniform, or the unique value (as character) otherwise.
#' 
#' @keywords internal
output.uniform <- function(x, na.rm=F) {
  y <- unique(as.character(x))
  if (na.rm) y <- setdiff(y, NA)
  if (length(y) == 1) return(y) else return(NA)
}
