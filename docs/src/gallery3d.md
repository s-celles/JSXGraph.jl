# 3D Gallery

A collection of 3D examples using JSXGraph's `View3D` viewport.
Each example demonstrates interactive 3D rendering with rotation via trackball.

## Basic 3D Geometry

### 1. Basic 3D Points

```@example gallery3d
using JSXGraph
b = board("points3d", xlim=(-8, 8), ylim=(-8, 8)) do b
    v = view3d([-6, -3], [8, 8], [[-5, 5], [-5, 5], [-5, 5]]) do v
        push!(v, point3d(1, 2, 3; size=5, name="A", color="red"))
        push!(v, point3d(-2, 1, 4; size=5, name="B", color="blue"))
        push!(v, point3d(3, -1, -2; size=5, name="C", color="green"))
    end
    push!(b, v)
end
b
```

### 2. 3D Line Through Two Points

```@example gallery3d
b = board("line3d_demo", xlim=(-8, 8), ylim=(-8, 8)) do b
    v = view3d([-6, -3], [8, 8], [[-5, 5], [-5, 5], [-5, 5]]) do v
        p1 = point3d(-3, -3, -3; size=4, name="P₁", color="red")
        p2 = point3d(3, 3, 3; size=4, name="P₂", color="blue")
        push!(v, p1)
        push!(v, p2)
        push!(v, line3d(p1, p2; strokeColor="purple", strokeWidth=2))
    end
    push!(b, v)
end
b
```

## Curves

### 3. Helix (Parametric 3D Curve)

```@example gallery3d
b = board("helix3d", xlim=(-8, 8), ylim=(-8, 8)) do b
    v = view3d([-6, -3], [8, 8], [[-5, 5], [-5, 5], [-5, 5]]) do v
        push!(v, curve3d(
            "Math.cos(t)", "Math.sin(t)", "t/(2*Math.PI)",
            [-2*π, 2*π];
            strokeColor="blue", strokeWidth=2,
        ))
    end
    push!(b, v)
end
b
```

### 4. Lissajous 3D Curve

```@example gallery3d
b = board("lissajous3d", xlim=(-8, 8), ylim=(-8, 8)) do b
    v = view3d([-6, -3], [8, 8], [[-3, 3], [-3, 3], [-3, 3]]) do v
        push!(v, curve3d(
            "2*Math.sin(3*t)", "2*Math.sin(2*t)", "2*Math.sin(5*t)",
            [0, 2*π];
            strokeColor="crimson", strokeWidth=2,
        ))
    end
    push!(b, v)
end
b
```

### 5. Conical Spiral

```@example gallery3d
b = board("spiral3d", xlim=(-8, 8), ylim=(-8, 8)) do b
    v = view3d([-6, -3], [8, 8], [[-5, 5], [-5, 5], [-1, 5]]) do v
        push!(v, curve3d(
            "t*Math.cos(4*t)/5", "t*Math.sin(4*t)/5", "t/5",
            [0, 5*π];
            strokeColor="darkorange", strokeWidth=2,
        ))
    end
    push!(b, v)
end
b
```

## Surfaces

### 6. Surface Plot — Sine Wave

```@example gallery3d
b = board("sine_surface", xlim=(-8, 8), ylim=(-8, 8)) do b
    v = view3d([-6, -3], [8, 8], [[-5, 5], [-5, 5], [-2, 2]]) do v
        push!(v, functiongraph3d("Math.sin(x)*Math.cos(y)";
            strokeWidth=0.5,
            stepsU=40, stepsV=40,
        ))
    end
    push!(b, v)
end
b
```

### 7. Saddle Surface

```@example gallery3d
b = board("saddle3d", xlim=(-8, 8), ylim=(-8, 8)) do b
    v = view3d([-6, -3], [8, 8], [[-3, 3], [-3, 3], [-5, 5]]) do v
        push!(v, functiongraph3d("x*x - y*y";
            strokeWidth=0.5,
            stepsU=30, stepsV=30,
        ))
    end
    push!(b, v)
end
b
```

### 8. Gaussian Surface

```@example gallery3d
b = board("gaussian3d", xlim=(-8, 8), ylim=(-8, 8)) do b
    v = view3d([-6, -3], [8, 8], [[-4, 4], [-4, 4], [-0.5, 2]]) do v
        push!(v, functiongraph3d("2*Math.exp(-(x*x + y*y)/2)";
            strokeWidth=0.5,
            stepsU=40, stepsV=40,
        ))
    end
    push!(b, v)
end
b
```

### 9. Ripple Surface

```@example gallery3d
b = board("ripple3d", xlim=(-8, 8), ylim=(-8, 8)) do b
    v = view3d([-6, -3], [8, 8], [[-5, 5], [-5, 5], [-2, 2]]) do v
        push!(v, functiongraph3d("Math.sin(Math.sqrt(x*x + y*y))";
            strokeWidth=0.5,
            stepsU=50, stepsV=50,
        ))
    end
    push!(b, v)
end
b
```

## Parametric Surfaces

### 10. Sphere

```@example gallery3d
b = board("sphere3d", xlim=(-8, 8), ylim=(-8, 8)) do b
    v = view3d([-6, -3], [8, 8], [[-3, 3], [-3, 3], [-3, 3]]) do v
        push!(v, parametricsurface3d(
            "2*Math.sin(u)*Math.cos(v)",
            "2*Math.sin(u)*Math.sin(v)",
            "2*Math.cos(u)",
            [0, π], [0, 2*π];
            strokeWidth=0.5,
            stepsU=30, stepsV=30,
        ))
    end
    push!(b, v)
end
b
```

### 11. Torus

```@example gallery3d
b = board("torus3d", xlim=(-8, 8), ylim=(-8, 8)) do b
    R = 3  # major radius
    r = 1  # minor radius
    v = view3d([-6, -3], [8, 8], [[-5, 5], [-5, 5], [-3, 3]]) do v
        push!(v, parametricsurface3d(
            "($R + $r*Math.cos(v))*Math.cos(u)",
            "($R + $r*Math.cos(v))*Math.sin(u)",
            "$r*Math.sin(v)",
            [0, 2*π], [0, 2*π];
            strokeWidth=0.5,
            stepsU=40, stepsV=20,
        ))
    end
    push!(b, v)
end
b
```

### 12. Möbius Strip

```@example gallery3d
b = board("mobius3d", xlim=(-8, 8), ylim=(-8, 8)) do b
    v = view3d([-6, -3], [8, 8], [[-4, 4], [-4, 4], [-2, 2]]) do v
        push!(v, parametricsurface3d(
            "(2 + u*Math.cos(v/2))*Math.cos(v)",
            "(2 + u*Math.cos(v/2))*Math.sin(v)",
            "u*Math.sin(v/2)",
            [-0.5, 0.5], [0, 2*π];
            strokeWidth=0.5,
            stepsU=10, stepsV=40,
        ))
    end
    push!(b, v)
end
b
```

### 13. Klein Bottle (Immersion)

```@example gallery3d
b = board("klein3d", xlim=(-8, 8), ylim=(-8, 8)) do b
    v = view3d([-6, -3], [8, 8], [[-5, 5], [-5, 5], [-5, 5]]) do v
        push!(v, parametricsurface3d(
            "(2 + Math.cos(u/2)*Math.sin(v) - Math.sin(u/2)*Math.sin(2*v))*Math.cos(u)",
            "(2 + Math.cos(u/2)*Math.sin(v) - Math.sin(u/2)*Math.sin(2*v))*Math.sin(u)",
            "Math.sin(u/2)*Math.sin(v) + Math.cos(u/2)*Math.sin(2*v)",
            [0, 2*π], [0, 2*π];
            strokeWidth=0.5,
            stepsU=40, stepsV=20,
        ))
    end
    push!(b, v)
end
b
```

## Combined Examples

### 14. Surface with Points

```@example gallery3d
b = board("surface_points", xlim=(-8, 8), ylim=(-8, 8)) do b
    v = view3d([-6, -3], [8, 8], [[-3, 3], [-3, 3], [-2, 2]]) do v
        push!(v, functiongraph3d("Math.sin(x)*Math.cos(y)";
            strokeWidth=0.5,
            stepsU=30, stepsV=30,
        ))
        # Mark some interesting points on the surface
        push!(v, point3d(0, 0, 0; size=5, color="red", name="Origin"))
        push!(v, point3d(π/2, 0, 1; size=5, color="blue", name="Max"))
        push!(v, point3d(-π/2, 0, -1; size=5, color="green", name="Min"))
    end
    push!(b, v)
end
b
```

### 15. Helix with Endpoints

```@example gallery3d
b = board("helix_endpoints", xlim=(-8, 8), ylim=(-8, 8)) do b
    v = view3d([-6, -3], [8, 8], [[-3, 3], [-3, 3], [-3, 3]]) do v
        push!(v, curve3d(
            "2*Math.cos(t)", "2*Math.sin(t)", "t/Math.PI",
            [0, 4*π];
            strokeColor="navy", strokeWidth=2,
        ))
        push!(v, point3d(2, 0, 0; size=5, color="red", name="Start"))
        push!(v, point3d(2, 0, 4; size=5, color="blue", name="End"))
    end
    push!(b, v)
end
b
```
