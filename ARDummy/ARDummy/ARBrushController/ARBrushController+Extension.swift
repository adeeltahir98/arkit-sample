//
//  ARBrushController+Extension.swift
//  ARDummy
//
//  Created by Adeel Tahir on 27/12/2022.
//

import Foundation
import SceneKit
import ARKit
import simd

extension ARBrushViewController: ARSCNViewDelegate {
    
    func getPointerPosition() -> (pos : SCNVector3, valid: Bool, camPos : SCNVector3 ) {
        
        // Un-project a 2d screen location into ARKit world space using the 'unproject'
        // function.
        
        guard let pointOfView = sceneView.pointOfView else { return (SCNVector3Zero, false, SCNVector3Zero) }
        guard let currentFrame = sceneView.session.currentFrame else { return (SCNVector3Zero, false, SCNVector3Zero) }
        
        let cameraPos = SCNVector3(currentFrame.camera.transform.translation)
        
        let touchLocationVec = SCNVector3(x: Float(touchLocation.x), y: Float(touchLocation.y), z: 0.01)
        
        let screenPosOnFarClippingPlane = self.sceneView.unprojectPoint(touchLocationVec)
        
        let dir = (screenPosOnFarClippingPlane - cameraPos).normalized()
        
        let worldTouchPos = cameraPos + dir * 0.12

        return (worldTouchPos, true, pointOfView.position)
        
    }
    
    //MARK: - ARSCNViewDelegate
    // Test mixing with scenekit content
    func addBall( _ pos : SCNVector3 ) {
        let b = SCNSphere(radius: 0.01)
        b.firstMaterial?.diffuse.contents = UIColor.red
        let n = SCNNode(geometry: b)
        n.worldPosition = pos
        self.sceneView.scene.rootNode.addChildNode(n)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        let pointer = getPointerPosition()
        
        if avgPos == nil {
            avgPos = pointer.pos
        }
        
        avgPos = avgPos - (avgPos - pointer.pos) * 0.4;
        
        if ( buttonDown ) {
            
            if ( pointer.valid ) {
                
                if ( vertBrush.points.count == 0 || (vertBrush.points.last! - pointer.pos).length() > 0.001 ) {
                    
                    var radius : Float = 0.001
                    
                    if ( splitLine || vertBrush.points.count < 2 ) {
                        lineRadius = 0.001
                    } else {
                        
                        let i = vertBrush.points.count-1
                        let p1 = vertBrush.points[i]
                        let p2 = vertBrush.points[i-1]
                        
                        radius = 0.001 + min(0.015, 0.005 * pow( ( p2-p1 ).length() / 0.005, 2))
                        
                    }
                    
                    lineRadius = lineRadius - (lineRadius - radius)*0.075
                    
                    var color : SCNVector3
                    
                    switch colorMode {
                        
                        case .rainbow:
                            
                            let hue : CGFloat = CGFloat(fmodf(Float(vertBrush.points.count) / 30.0, 1.0))
                            let c = UIColor.init(hue: hue, saturation: 0.95, brightness: 0.95, alpha: 1.0)
                            var red : CGFloat = 0.0; var green : CGFloat = 0.0; var blue : CGFloat = 0.0;
                            c.getRed(&red, green: &green, blue: &blue, alpha: nil)
                            color = SCNVector3(red, green, blue)
                            
                        case .normal:
                            // Hack: if the color is negative, use the normal as the color
                            color = SCNVector3(-1, -1, -1)
                            
                        case .color:
                            color = self.currentColor
                    
                    }
                    
                    vertBrush.addPoint(avgPos,
                                       radius: lineRadius,
                                       color: color,
                                       splitLine:splitLine)
                    
                    if ( splitLine ) { splitLine = false }
                    
                }
                
            }
            
        }
        
        
        frameIdx = frameIdx + 1
        
    }
    
    
    
    func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        

        if ( !hasSetupPipeline ) {
            // pixelFormat is different if called at viewWillAppear
            hasSetupPipeline = true
            
            vertBrush.setupPipeline(device: sceneView.device!, renderDestination: self.sceneView! )
        }
        
        guard let frame = self.sceneView.session.currentFrame else {
            return
        }
        
        if let commandQueue = self.sceneView?.commandQueue {
            if let encoder = self.sceneView.currentRenderCommandEncoder {
                
                let projMat = float4x4.init((self.sceneView.pointOfView?.camera?.projectionTransform)!)
                let modelViewMat = float4x4.init((self.sceneView.pointOfView?.worldTransform)!).inverse
                
                vertBrush.updateSharedUniforms(frame: frame)
                vertBrush.render(commandQueue, encoder, parentModelViewMatrix: modelViewMat, projectionMatrix: projMat)
                
                
            }
        }
        
        
        
        // This is not the right way to do this ..
        // seems to work though
        DispatchQueue.global(qos: .userInteractive).async {

            if let recorder = self.videoRecorder,
                recorder.isRecording {

                if let tex = self.metalLayer.nextDrawable()?.texture {
                    recorder.writeFrame(forTexture: tex)
                }
            }
        }
        
    }
    

    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
