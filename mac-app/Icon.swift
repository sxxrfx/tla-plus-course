import AppKit
import Foundation

let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
for size in [16,32,64,128,256,512,1024] {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    let scale = CGFloat(size) / 1024
    let transform = NSAffineTransform(); transform.scale(by: scale); transform.concat()
    NSColor(red:0.21,green:0.29,blue:0.66,alpha:1).setFill()
    NSBezierPath(roundedRect:NSRect(x:32,y:32,width:960,height:960),xRadius:205,yRadius:205).fill()
    NSColor.white.withAlphaComponent(0.8).setStroke()
    let edges=NSBezierPath();edges.lineWidth=20
    edges.move(to:NSPoint(x:260,y:665));edges.line(to:NSPoint(x:512,y:800));edges.line(to:NSPoint(x:764,y:665));edges.line(to:NSPoint(x:260,y:665));edges.stroke()
    for p in [NSPoint(x:260,y:665),NSPoint(x:512,y:800),NSPoint(x:764,y:665)] {
        NSColor.white.setFill();NSBezierPath(ovalIn:NSRect(x:p.x-44,y:p.y-44,width:88,height:88)).fill()
    }
    let title="TLA+" as NSString
    let attributes: [NSAttributedString.Key:Any] = [.font:NSFont.systemFont(ofSize:235,weight:.semibold),.foregroundColor:NSColor.white]
    let width=title.size(withAttributes:attributes).width
    title.draw(at:NSPoint(x:(1024-width)/2,y:210),withAttributes:attributes)
    image.unlockFocus()
    guard let tiff=image.tiffRepresentation,let rep=NSBitmapImageRep(data:tiff),let png=rep.representation(using:.png,properties:[:]) else { fatalError("Could not render app icon") }
    let names: [String]
    switch size {
    case 16:names=["icon_16x16.png"]
    case 32:names=["icon_16x16@2x.png","icon_32x32.png"]
    case 64:names=["icon_32x32@2x.png"]
    case 128:names=["icon_128x128.png"]
    case 256:names=["icon_128x128@2x.png","icon_256x256.png"]
    case 512:names=["icon_256x256@2x.png","icon_512x512.png"]
    default:names=["icon_512x512@2x.png"]
    }
    for name in names { try png.write(to:output.appendingPathComponent(name)) }
}
