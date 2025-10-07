import React, { useRef, useEffect, useState } from 'react';

/**
 * CrossReferenceAnimation Component
 * 
 * Animates connections between Bible verses with smooth transitions:
 * - Zoom/pan to starting verse
 * - Pulsing glow on start verse
 * - Animated line drawing from start to end
 * - Glowing trail effect
 * - Destination verse highlight
 */

const CrossReferenceAnimation = ({ width = 800, height = 600 }) => {
  const svgRef = useRef(null);
  const [verses, setVerses] = useState([]);
  const [connections, setConnections] = useState([]);
  const [viewBox, setViewBox] = useState({ x: 0, y: 0, width, height });
  const animationFrameRef = useRef(null);

  // Easing function: easeInOutQuad
  const easeInOutQuad = (t) => {
    return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
  };

  // Easing function: easeOutCubic for smoother deceleration
  const easeOutCubic = (t) => {
    return 1 - Math.pow(1 - t, 3);
  };

  /**
   * Animate the viewBox to zoom/pan to a specific verse
   */
  const animateViewBox = (targetX, targetY, zoomLevel = 2, duration = 800) => {
    return new Promise((resolve) => {
      const startTime = Date.now();
      const startViewBox = { ...viewBox };
      const targetWidth = width / zoomLevel;
      const targetHeight = height / zoomLevel;
      const targetViewBox = {
        x: targetX - targetWidth / 2,
        y: targetY - targetHeight / 2,
        width: targetWidth,
        height: targetHeight,
      };

      const animate = () => {
        const elapsed = Date.now() - startTime;
        const progress = Math.min(elapsed / duration, 1);
        const easedProgress = easeInOutQuad(progress);

        setViewBox({
          x: startViewBox.x + (targetViewBox.x - startViewBox.x) * easedProgress,
          y: startViewBox.y + (targetViewBox.y - startViewBox.y) * easedProgress,
          width: startViewBox.width + (targetViewBox.width - startViewBox.width) * easedProgress,
          height: startViewBox.height + (targetViewBox.height - startViewBox.height) * easedProgress,
        });

        if (progress < 1) {
          animationFrameRef.current = requestAnimationFrame(animate);
        } else {
          resolve();
        }
      };

      animate();
    });
  };

  /**
   * Reset view to show all verses
   */
  const resetView = (duration = 600) => {
    return new Promise((resolve) => {
      const startTime = Date.now();
      const startViewBox = { ...viewBox };
      const targetViewBox = { x: 0, y: 0, width, height };

      const animate = () => {
        const elapsed = Date.now() - startTime;
        const progress = Math.min(elapsed / duration, 1);
        const easedProgress = easeOutCubic(progress);

        setViewBox({
          x: startViewBox.x + (targetViewBox.x - startViewBox.x) * easedProgress,
          y: startViewBox.y + (targetViewBox.y - startViewBox.y) * easedProgress,
          width: startViewBox.width + (targetViewBox.width - startViewBox.width) * easedProgress,
          height: startViewBox.height + (targetViewBox.height - startViewBox.height) * easedProgress,
        });

        if (progress < 1) {
          animationFrameRef.current = requestAnimationFrame(animate);
        } else {
          resolve();
        }
      };

      animate();
    });
  };

  /**
   * Main animation function: connects two verses with animated line
   * 
   * @param {Object} startVerse - { id, x, y, text }
   * @param {Object} endVerse - { id, x, y, text }
   * @param {string} color - Line color (e.g., '#6366f1')
   */
  const animateCrossReference = async (startVerse, endVerse, color = '#6366f1') => {
    // Step 1: Zoom into starting verse
    await animateViewBox(startVerse.x, startVerse.y, 1.5, 800);

    // Step 2: Add glow to starting verse (handled by CSS animation)
    const startElement = document.getElementById(`verse-${startVerse.id}`);
    if (startElement) {
      startElement.classList.add('verse-glow-start');
    }

    // Wait for glow pulse
    await new Promise(resolve => setTimeout(resolve, 600));

    // Step 3: Zoom out slightly to show both verses
    const midX = (startVerse.x + endVerse.x) / 2;
    const midY = (startVerse.y + endVerse.y) / 2;
    const distance = Math.sqrt(
      Math.pow(endVerse.x - startVerse.x, 2) + 
      Math.pow(endVerse.y - startVerse.y, 2)
    );
    const zoomLevel = Math.max(1, Math.min(1.8, 600 / distance));
    await animateViewBox(midX, midY, zoomLevel, 600);

    // Step 4: Animate the connection line
    const connection = {
      id: `connection-${Date.now()}`,
      startVerse,
      endVerse,
      color,
      progress: 0,
      isAnimating: true,
    };

    setConnections(prev => [...prev, connection]);

    // Animate line progress
    const lineAnimationDuration = 1200;
    const lineStartTime = Date.now();

    const animateLine = () => {
      const elapsed = Date.now() - lineStartTime;
      const progress = Math.min(elapsed / lineAnimationDuration, 1);
      const easedProgress = easeInOutQuad(progress);

      setConnections(prev => 
        prev.map(conn => 
          conn.id === connection.id 
            ? { ...conn, progress: easedProgress }
            : conn
        )
      );

      if (progress < 1) {
        animationFrameRef.current = requestAnimationFrame(animateLine);
      } else {
        // Step 5: Glow destination verse
        const endElement = document.getElementById(`verse-${endVerse.id}`);
        if (endElement) {
          endElement.classList.add('verse-glow-end');
          setTimeout(() => {
            endElement.classList.remove('verse-glow-end');
          }, 1000);
        }

        // Mark line animation as complete
        setConnections(prev => 
          prev.map(conn => 
            conn.id === connection.id 
              ? { ...conn, isAnimating: false }
              : conn
          )
        );

        // Remove start glow
        if (startElement) {
          startElement.classList.remove('verse-glow-start');
        }

        // Reset view after animation
        setTimeout(() => {
          resetView();
        }, 800);
      }
    };

    animateLine();
  };

  /**
   * Generate a curved path between two points
   */
  const generateCurvePath = (x1, y1, x2, y2) => {
    const dx = x2 - x1;
    const dy = y2 - y1;
    const distance = Math.sqrt(dx * dx + dy * dy);
    
    // Control point for quadratic bezier curve
    const curvature = 0.2;
    const controlX = (x1 + x2) / 2 + (-dy * curvature);
    const controlY = (y1 + y2) / 2 + (dx * curvature);

    return `M ${x1} ${y1} Q ${controlX} ${controlY} ${x2} ${y2}`;
  };

  /**
   * Get the total length of a path (for stroke animation)
   */
  const getPathLength = (pathD) => {
    const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
    path.setAttribute('d', pathD);
    return path.getTotalLength();
  };

  // Initialize with sample verses
  useEffect(() => {
    const sampleVerses = [
      { id: 1, x: 200, y: 150, text: 'John 3:16', reference: 'John 3:16' },
      { id: 2, x: 600, y: 200, text: 'Romans 5:8', reference: 'Romans 5:8' },
      { id: 3, x: 300, y: 400, text: '1 John 4:9', reference: '1 John 4:9' },
      { id: 4, x: 500, y: 450, text: 'Ephesians 2:8', reference: 'Ephesians 2:8' },
    ];
    setVerses(sampleVerses);
  }, []);

  // Demo: Trigger animation on mount
  useEffect(() => {
    if (verses.length >= 2) {
      const timer = setTimeout(() => {
        animateCrossReference(verses[0], verses[1], '#6366f1');
      }, 1000);
      return () => clearTimeout(timer);
    }
  }, [verses]);

  // Cleanup animation frames on unmount
  useEffect(() => {
    return () => {
      if (animationFrameRef.current) {
        cancelAnimationFrame(animationFrameRef.current);
      }
    };
  }, []);

  return (
    <div className="cross-reference-container">
      <svg
        ref={svgRef}
        viewBox={`${viewBox.x} ${viewBox.y} ${viewBox.width} ${viewBox.height}`}
        style={{
          width: '100%',
          height: '100%',
          background: '#1a1a2e',
          transition: 'none', // We handle transitions manually
        }}
      >
        {/* Define glow filters */}
        <defs>
          <filter id="glow" x="-50%" y="-50%" width="200%" height="200%">
            <feGaussianBlur stdDeviation="4" result="coloredBlur" />
            <feMerge>
              <feMergeNode in="coloredBlur" />
              <feMergeNode in="SourceGraphic" />
            </feMerge>
          </filter>

          <filter id="line-glow" x="-50%" y="-50%" width="200%" height="200%">
            <feGaussianBlur stdDeviation="3" result="coloredBlur" />
            <feMerge>
              <feMergeNode in="coloredBlur" />
              <feMergeNode in="SourceGraphic" />
            </feMerge>
          </filter>

          {/* Gradient for glowing effect */}
          <radialGradient id="glowGradient">
            <stop offset="0%" stopColor="#6366f1" stopOpacity="0.8" />
            <stop offset="100%" stopColor="#6366f1" stopOpacity="0" />
          </radialGradient>
        </defs>

        {/* Render connection lines */}
        {connections.map((conn) => {
          const pathD = generateCurvePath(
            conn.startVerse.x,
            conn.startVerse.y,
            conn.endVerse.x,
            conn.endVerse.y
          );
          const pathLength = 300; // Approximate for performance

          return (
            <g key={conn.id}>
              {/* Base line (full path, faded) */}
              {!conn.isAnimating && (
                <path
                  d={pathD}
                  stroke={conn.color}
                  strokeWidth="2"
                  fill="none"
                  opacity="0.3"
                />
              )}

              {/* Animated line with glow */}
              {conn.isAnimating && (
                <>
                  <path
                    d={pathD}
                    stroke={conn.color}
                    strokeWidth="3"
                    fill="none"
                    filter="url(#line-glow)"
                    opacity="0.9"
                    strokeDasharray={pathLength}
                    strokeDashoffset={pathLength * (1 - conn.progress)}
                    strokeLinecap="round"
                  />
                  {/* Moving glow point */}
                  {conn.progress > 0 && conn.progress < 1 && (
                    <circle
                      cx={
                        conn.startVerse.x +
                        (conn.endVerse.x - conn.startVerse.x) * conn.progress
                      }
                      cy={
                        conn.startVerse.y +
                        (conn.endVerse.y - conn.startVerse.y) * conn.progress
                      }
                      r="6"
                      fill={conn.color}
                      filter="url(#glow)"
                      opacity="0.8"
                    />
                  )}
                </>
              )}
            </g>
          );
        })}

        {/* Render verses */}
        {verses.map((verse) => (
          <g key={verse.id} id={`verse-${verse.id}`} className="verse-node">
            <circle
              cx={verse.x}
              cy={verse.y}
              r="25"
              fill="#4f46e5"
              stroke="#818cf8"
              strokeWidth="2"
              className="verse-circle"
            />
            <text
              x={verse.x}
              y={verse.y + 45}
              textAnchor="middle"
              fill="#e0e7ff"
              fontSize="14"
              fontWeight="500"
            >
              {verse.reference}
            </text>
          </g>
        ))}
      </svg>

      {/* Control buttons */}
      <div className="controls">
        <button
          onClick={() => {
            if (verses.length >= 2) {
              animateCrossReference(verses[0], verses[1], '#6366f1');
            }
          }}
        >
          Animate Connection 1→2
        </button>
        <button
          onClick={() => {
            if (verses.length >= 4) {
              animateCrossReference(verses[2], verses[3], '#8b5cf6');
            }
          }}
        >
          Animate Connection 3→4
        </button>
        <button onClick={() => resetView()}>Reset View</button>
      </div>

      <style>{`
        .cross-reference-container {
          width: 100%;
          height: 100vh;
          position: relative;
          overflow: hidden;
        }

        .controls {
          position: absolute;
          top: 20px;
          left: 20px;
          display: flex;
          gap: 10px;
          flex-direction: column;
        }

        .controls button {
          background: #4f46e5;
          color: white;
          border: none;
          padding: 12px 20px;
          border-radius: 8px;
          cursor: pointer;
          font-size: 14px;
          font-weight: 500;
          transition: all 0.3s ease;
          box-shadow: 0 2px 8px rgba(79, 70, 229, 0.3);
        }

        .controls button:hover {
          background: #4338ca;
          transform: translateY(-2px);
          box-shadow: 0 4px 12px rgba(79, 70, 229, 0.4);
        }

        .controls button:active {
          transform: translateY(0);
        }

        /* Verse glow animations */
        @keyframes pulse-glow-start {
          0%, 100% {
            filter: drop-shadow(0 0 8px rgba(99, 102, 241, 0.6));
          }
          50% {
            filter: drop-shadow(0 0 20px rgba(99, 102, 241, 1));
          }
        }

        @keyframes pulse-glow-end {
          0% {
            filter: drop-shadow(0 0 8px rgba(139, 92, 246, 0.6));
          }
          50% {
            filter: drop-shadow(0 0 24px rgba(139, 92, 246, 1));
          }
          100% {
            filter: drop-shadow(0 0 8px rgba(139, 92, 246, 0));
          }
        }

        .verse-node.verse-glow-start {
          animation: pulse-glow-start 1.2s ease-in-out infinite;
        }

        .verse-node.verse-glow-end {
          animation: pulse-glow-end 1s ease-out;
        }

        .verse-circle {
          transition: all 0.3s ease;
        }

        .verse-node:hover .verse-circle {
          r: 30;
          filter: drop-shadow(0 0 12px rgba(99, 102, 241, 0.8));
        }

        /* Mobile optimizations */
        @media (max-width: 768px) {
          .controls {
            flex-direction: row;
            flex-wrap: wrap;
            top: auto;
            bottom: 20px;
          }

          .controls button {
            flex: 1;
            min-width: 120px;
            padding: 10px 16px;
            font-size: 12px;
          }
        }
      `}</style>
    </div>
  );
};

export default CrossReferenceAnimation;

