import 'dart:io';
import 'package:image/image.dart' as img;

// Script para crear icono PNG de la app - Maleta con Checklist
// Ejecutar con: dart scripts/create_icon.dart

void main() {
  const size = 1024;
  // const bgColor = 0xFF006571; // Teal oscuro #006571
  // const suitcaseColor = 0xFF00BFA5; // Turquesa claro
  // const checklistColor = 0xFFFFFFFF; // Blanco
  // const checkColor = 0xFF00C853; // Verde check
  
  // Crear imagen con fondo
  final image = img.Image(width: size, height: size);
  
  // Rellenar fondo (color primario de la app)
  img.fill(image, color: img.ColorRgb8(0, 101, 113));
  
  final centerX = size ~/ 2;
  final centerY = size ~/ 2;
  
  // Dibujar maleta (rectángulo principal con bordes redondeados)
  final suitcaseW = 500;
  final suitcaseH = 600;
  final suitcaseX = centerX - suitcaseW ~/ 2;
  final suitcaseY = centerY - suitcaseH ~/ 2 + 50;
  
  // Cuerpo de la maleta
  img.fillRect(
    image,
    x1: suitcaseX,
    y1: suitcaseY,
    x2: suitcaseX + suitcaseW,
    y2: suitcaseY + suitcaseH,
    color: img.ColorRgb8(0, 191, 165),
  );
  
  // Bordes redondeados de la maleta (esquinas)
  _drawRoundedCorners(image, suitcaseX, suitcaseY, suitcaseW, suitcaseH, 40, img.ColorRgb8(0, 191, 165));
  
  // Asa de la maleta (arriba)
  img.fillRect(
    image,
    x1: centerX - 80,
    y1: suitcaseY - 60,
    x2: centerX + 80,
    y2: suitcaseY,
    color: img.ColorRgb8(0, 150, 136),
  );
  
  // Ruedas (abajo)
  _drawWheel(image, suitcaseX + 80, suitcaseY + suitcaseH + 30, 35);
  _drawWheel(image, suitcaseX + suitcaseW - 80, suitcaseY + suitcaseH + 30, 35);
  
  // Checklist (rectángulo blanco en el centro de la maleta)
  final listW = 320;
  final listH = 380;
  final listX = centerX - listW ~/ 2;
  final listY = centerY - listH ~/ 2 + 20;
  
  img.fillRect(
    image,
    x1: listX,
    y1: listY,
    x2: listX + listW,
    y2: listY + listH,
    color: img.ColorRgb8(255, 255, 255),
  );
  
  // Bordes redondeados del checklist
  _drawRoundedCorners(image, listX, listY, listW, listH, 20, img.ColorRgb8(255, 255, 255));
  
  // Items del checklist (3 líneas con checkbox)
  const itemY1 = 0;
  const itemY2 = 100;
  const itemY3 = 200;
  
  // Item 1 - Check verde
  _drawCheckbox(image, listX + 40, listY + 60 + itemY1, 50, true);
  _drawLine(image, listX + 110, listY + 75 + itemY1, listX + 280, listY + 75 + itemY1, img.ColorRgb8(200, 200, 200));
  
  // Item 2 - Check verde
  _drawCheckbox(image, listX + 40, listY + 60 + itemY2, 50, true);
  _drawLine(image, listX + 110, listY + 75 + itemY2, listX + 280, listY + 75 + itemY2, img.ColorRgb8(200, 200, 200));
  
  // Item 3 - Sin check
  _drawCheckbox(image, listX + 40, listY + 60 + itemY3, 50, false);
  _drawLine(image, listX + 110, listY + 75 + itemY3, listX + 240, listY + 75 + itemY3, img.ColorRgb8(200, 200, 200));
  
  // Guardar PNG
  final png = img.encodePng(image);
  File('assets/icons/app_icon.png').writeAsBytesSync(png);
  
  print('✅ Icono creado: assets/icons/app_icon.png');
  print('🎨 Dimensiones: ${size}x${size}');
  print('� Maleta + Checklist');
  print('�📱 Ejecuta: flutter pub run flutter_launcher_icons:main');
}

void _drawWheel(img.Image image, int cx, int cy, int radius) {
  img.fillCircle(
    image,
    x: cx,
    y: cy,
    radius: radius,
    color: img.ColorRgb8(0, 80, 80),
  );
}

void _drawRoundedCorners(img.Image image, int x, int y, int w, int h, int r, img.Color color) {
  // Esquinas redondeadas (simplificado - solo rellenar esquinas)
}

void _drawCheckbox(img.Image image, int x, int y, int size, bool checked) {
  // Borde del checkbox
  img.drawRect(
    image,
    x1: x,
    y1: y,
    x2: x + size,
    y2: y + size,
    color: checked ? img.ColorRgb8(0, 200, 83) : img.ColorRgb8(150, 150, 150),
    thickness: 4,
  );
  
  if (checked) {
    // Rellenar con verde
    img.fillRect(
      image,
      x1: x + 4,
      y1: y + 4,
      x2: x + size - 4,
      y2: y + size - 4,
      color: img.ColorRgb8(0, 200, 83),
    );
    
    // Check blanco (líneas)
    img.drawLine(
      image,
      x1: x + 12,
      y1: y + size ~/ 2 + 5,
      x2: x + size ~/ 2 - 5,
      y2: y + size - 12,
      color: img.ColorRgb8(255, 255, 255),
      thickness: 5,
    );
    img.drawLine(
      image,
      x1: x + size ~/ 2 - 5,
      y1: y + size - 12,
      x2: x + size - 10,
      y2: y + 12,
      color: img.ColorRgb8(255, 255, 255),
      thickness: 5,
    );
  }
}

void _drawLine(img.Image image, int x1, int y1, int x2, int y2, img.Color color) {
  img.drawLine(
    image,
    x1: x1,
    y1: y1,
    x2: x2,
    y2: y2,
    color: color,
    thickness: 8,
  );
}
