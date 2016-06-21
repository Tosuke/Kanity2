module kanity.drawing.utils;

import kanity.imports;
import kanity.drawing.imports;

mat4 orthographicMatrix(real left, real right,
                        real bottom, real top,
                        real near, real far){
    assert(left != right);
    assert(bottom != top);
    assert(near != far);
    
    return mat4.identity.translate((left + right) / -2.0, (bottom + top) / -2.0, (near + far) / -2.0)
                        .scale(2.0 / (right - left), 2.0 / (top - bottom), 2.0 / (far - near));
}
