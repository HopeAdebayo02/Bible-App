/**
 * Cross Reference Animation Utilities
 * 
 * Reusable helper functions for animating Bible verse cross-references.
 * Can be imported into any JavaScript project.
 * 
 * Usage:
 *   import { CrossReferenceAnimator } from './animation-utils.js';
 *   
 *   const animator = new CrossReferenceAnimator(svgElement);
 *   animator.connect(verse1, verse2, { color: '#6366f1', duration: 1200 });
 */

// ==================== Easing Functions ====================

export const Easing = {
  linear: (t) => t,
  
  easeInQuad: (t) => t * t,
  easeOutQuad: (t) => t * (2 - t),
  easeInOutQuad: (t) => t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t,
  
  easeInCubic: (t) => t * t * t,
  easeOutCubic: (t) => 1 - Math.pow(1 - t, 3),
  easeInOutCubic: (t) => t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2,
  
  easeInOutElastic: (t) => {
    const c5 = (2 * Math.PI) / 4.5;
    return t === 0 ? 0 : t === 1 ? 1 : t < 0.5
      ? -(Math.pow(2, 20 * t - 10) * Math.sin((20 * t - 11.125) * c5)) / 2
      : (Math.pow(2, -20 * t + 10) * Math.sin((20 * t - 11.125) * c5)) / 2 + 1;
  }
};

// ==================== Utility Functions ====================

export const Utils = {
  /**
   * Linear interpolation between two values
   */
  lerp(start, end, t) {
    return start + (end - start) * t;
  },

  /**
   * Calculate distance between two points
   */
  distance(x1, y1, x2, y2) {
    return Math.sqrt(Math.pow(x2 - x1, 2) + Math.pow(y2 - y1, 2));
  },

  /**
   * Generate a quadratic bezier curve path between two points
   */
  generateCurvePath(x1, y1, x2, y2, curvature = 0.25) {
    const dx = x2 - x1;
    const dy = y2 - y1;
    const controlX = (x1 + x2) / 2 + (-dy * curvature);
    const controlY = (y1 + y2) / 2 + (dx * curvature);
    return `M ${x1} ${y1} Q ${controlX} ${controlY} ${x2} ${y2}`;
  },

  /**
   * Get the total length of an SVG path
   */
  getPathLength(pathElement) {
    return pathElement.getTotalLength();
  },

  /**
   * Create SVG element with attributes
   */
  createSVGElement(tag, attributes = {}) {
    const element = document.createElementNS('http://www.w3.org/2000/svg', tag);
    Object.entries(attributes).forEach(([key, value]) => {
      element.setAttribute(key, value);
    });
    return element;
  },

  /**
   * Delay execution
   */
  delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
};

// ==================== Main Animator Class ====================

export class CrossReferenceAnimator {
  constructor(svgElement, options = {}) {
    this.svg = svgElement;
    this.options = {
      defaultColor: '#6366f1',
      defaultDuration: 1200,
      zoomDuration: 800,
      glowDuration: 600,
      lineWidth: 3,
      glowRadius: 6,
      ...options
    };
    
    this.connections = [];
    this.isAnimating = false;
    this.currentViewBox = this.getViewBox();
    
    this.initializeFilters();
  }

  /**
   * Initialize SVG filters for glow effects
   */
  initializeFilters() {
    let defs = this.svg.querySelector('defs');
    if (!defs) {
      defs = Utils.createSVGElement('defs');
      this.svg.insertBefore(defs, this.svg.firstChild);
    }

    // Glow filter
    const glowFilter = Utils.createSVGElement('filter', {
      id: 'cross-ref-glow',
      x: '-50%',
      y: '-50%',
      width: '200%',
      height: '200%'
    });
    
    const blur = Utils.createSVGElement('feGaussianBlur', {
      stdDeviation: this.options.glowRadius,
      result: 'coloredBlur'
    });
    
    const merge = Utils.createSVGElement('feMerge');
    merge.appendChild(Utils.createSVGElement('feMergeNode', { in: 'coloredBlur' }));
    merge.appendChild(Utils.createSVGElement('feMergeNode', { in: 'SourceGraphic' }));
    
    glowFilter.appendChild(blur);
    glowFilter.appendChild(merge);
    defs.appendChild(glowFilter);
  }

  /**
   * Get current viewBox values
   */
  getViewBox() {
    const vb = this.svg.getAttribute('viewBox').split(' ').map(Number);
    return { x: vb[0], y: vb[1], width: vb[2], height: vb[3] };
  }

  /**
   * Set viewBox
   */
  setViewBox(x, y, width, height) {
    this.svg.setAttribute('viewBox', `${x} ${y} ${width} ${height}`);
    this.currentViewBox = { x, y, width, height };
  }

  /**
   * Animate viewBox transformation
   */
  animateViewBox(targetX, targetY, targetWidth, targetHeight, duration, easingFunc = Easing.easeInOutQuad) {
    return new Promise(resolve => {
      const startTime = performance.now();
      const startVB = { ...this.currentViewBox };

      const animate = (currentTime) => {
        const elapsed = currentTime - startTime;
        const progress = Math.min(elapsed / duration, 1);
        const eased = easingFunc(progress);

        this.setViewBox(
          Utils.lerp(startVB.x, targetX, eased),
          Utils.lerp(startVB.y, targetY, eased),
          Utils.lerp(startVB.width, targetWidth, eased),
          Utils.lerp(startVB.height, targetHeight, eased)
        );

        if (progress < 1) {
          requestAnimationFrame(animate);
        } else {
          resolve();
        }
      };

      requestAnimationFrame(animate);
    });
  }

  /**
   * Add glow animation to an element
   */
  addGlow(element, duration) {
    return new Promise(resolve => {
      element.style.filter = 'drop-shadow(0 0 20px currentColor)';
      element.style.transition = `filter ${duration}ms ease-in-out`;
      
      const keyframes = [
        { filter: 'drop-shadow(0 0 8px currentColor)' },
        { filter: 'drop-shadow(0 0 25px currentColor)' },
        { filter: 'drop-shadow(0 0 8px currentColor)' }
      ];
      
      const animation = element.animate(keyframes, {
        duration: duration,
        iterations: Infinity,
        easing: 'ease-in-out'
      });

      setTimeout(() => {
        animation.cancel();
        element.style.filter = '';
        resolve();
      }, duration * 2);
    });
  }

  /**
   * Animate a path being drawn
   */
  animatePath(pathElement, color, duration) {
    return new Promise(resolve => {
      const length = Utils.getPathLength(pathElement);
      pathElement.style.strokeDasharray = length;
      pathElement.style.strokeDashoffset = length;

      const startTime = performance.now();

      // Create moving glow dot
      const glowDot = Utils.createSVGElement('circle', {
        r: '8',
        fill: color,
        filter: 'url(#cross-ref-glow)',
        opacity: '0.9'
      });
      pathElement.parentElement.appendChild(glowDot);

      const animate = (currentTime) => {
        const elapsed = currentTime - startTime;
        const progress = Math.min(elapsed / duration, 1);
        const eased = Easing.easeInOutCubic(progress);

        pathElement.style.strokeDashoffset = length * (1 - eased);

        // Move glow dot
        const point = pathElement.getPointAtLength(length * eased);
        glowDot.setAttribute('cx', point.x);
        glowDot.setAttribute('cy', point.y);

        if (progress < 1) {
          requestAnimationFrame(animate);
        } else {
          // Remove glow dot
          glowDot.style.transition = 'opacity 0.3s';
          glowDot.style.opacity = '0';
          setTimeout(() => glowDot.remove(), 300);
          resolve();
        }
      };

      requestAnimationFrame(animate);
    });
  }

  /**
   * Main function: Connect two verses with animation
   * 
   * @param {Object} startVerse - { x, y, element }
   * @param {Object} endVerse - { x, y, element }
   * @param {Object} options - { color, duration, skipZoom }
   */
  async connect(startVerse, endVerse, options = {}) {
    if (this.isAnimating) {
      console.warn('Animation already in progress');
      return;
    }

    this.isAnimating = true;
    const color = options.color || this.options.defaultColor;
    const duration = options.duration || this.options.defaultDuration;
    const skipZoom = options.skipZoom || false;

    try {
      if (!skipZoom) {
        // Step 1: Zoom to start verse
        const zoomWidth = 400;
        const zoomHeight = 280;
        await this.animateViewBox(
          startVerse.x - zoomWidth / 2,
          startVerse.y - zoomHeight / 2,
          zoomWidth,
          zoomHeight,
          this.options.zoomDuration
        );

        // Step 2: Glow start verse
        const glowPromise = this.addGlow(startVerse.element, this.options.glowDuration);
        await Utils.delay(this.options.glowDuration);

        // Step 3: Zoom to show both verses
        const dist = Utils.distance(startVerse.x, startVerse.y, endVerse.x, endVerse.y);
        const padding = 200;
        const viewWidth = dist + padding;
        const viewHeight = viewWidth * 0.7;
        const centerX = (startVerse.x + endVerse.x) / 2;
        const centerY = (startVerse.y + endVerse.y) / 2;

        await this.animateViewBox(
          centerX - viewWidth / 2,
          centerY - viewHeight / 2,
          viewWidth,
          viewHeight,
          600,
          Easing.easeOutCubic
        );
      }

      // Step 4: Draw connection line
      const pathD = Utils.generateCurvePath(
        startVerse.x, startVerse.y,
        endVerse.x, endVerse.y
      );

      const path = Utils.createSVGElement('path', {
        d: pathD,
        stroke: color,
        'stroke-width': this.options.lineWidth,
        fill: 'none',
        filter: 'url(#cross-ref-glow)',
        opacity: '0.9',
        'stroke-linecap': 'round'
      });

      // Add to connections group or svg
      const connectionsGroup = this.svg.querySelector('#connections') || this.svg;
      connectionsGroup.appendChild(path);

      await this.animatePath(path, color, duration);

      // Step 5: Glow end verse
      const endGlowKeyframes = [
        { filter: 'drop-shadow(0 0 10px ' + color + ')' },
        { filter: 'drop-shadow(0 0 30px ' + color + ')' },
        { filter: 'drop-shadow(0 0 0 transparent)' }
      ];
      
      endVerse.element.animate(endGlowKeyframes, {
        duration: 1000,
        easing: 'ease-out'
      });

      // Make line permanent (faded)
      path.style.strokeDasharray = 'none';
      path.style.strokeDashoffset = '0';
      path.setAttribute('opacity', '0.4');

      this.connections.push({ startVerse, endVerse, path, color });

    } finally {
      this.isAnimating = false;
    }
  }

  /**
   * Clear all connections
   */
  clearConnections() {
    this.connections.forEach(conn => conn.path.remove());
    this.connections = [];
  }

  /**
   * Reset view to original viewBox
   */
  async resetView(originalViewBox = null) {
    const target = originalViewBox || { x: 0, y: 0, width: 1000, height: 700 };
    await this.animateViewBox(
      target.x,
      target.y,
      target.width,
      target.height,
      800,
      Easing.easeOutCubic
    );
  }
}

// ==================== Export Default ====================

export default {
  CrossReferenceAnimator,
  Easing,
  Utils
};

