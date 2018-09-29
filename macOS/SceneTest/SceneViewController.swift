//
//  SceneViewController.swift
//  SceneTest
//
//  Created by 浅野　宏明 on 2018/05/27.
//  Copyright © 2018年 akylab. All rights reserved.
//

import SceneKit
import QuartzCore
import MultipeerConnectivity
import AudioToolbox

class SceneViewController: NSViewController {
    
    var scene = SCNScene()
    var baseYaw: Double?
    
    static let peerID = MCPeerID(displayName: "macbook")
    
    var session: MCSession?
    var browser: MCNearbyServiceBrowser?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        connect()
        
        startUpdatingVolume()
        
        let url = Bundle.main.url(forResource: "art.scnassets/link/link", withExtension: "dae")!
        scene = try! SCNScene(url: url, options: nil)
        
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 10)
        scene.rootNode.addChildNode(cameraNode)
        
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = NSColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
        
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        scnView.scene = scene
        scnView.allowsCameraControl = true
        scnView.backgroundColor = .clear
        
        // additional
        scene.rootNode.childNode(withName: "skl_root", recursively: true)!.scale = SCNVector3(x: 10, y: 10, z: 10)
        scene.rootNode.childNode(withName: "skl_root", recursively: true)!.position = SCNVector3(x: 0, y: -8, z: 0)
        
        scene.rootNode.childNode(withName: "body_0_0_node", recursively: true)!.removeFromParentNode()
        scene.rootNode.childNode(withName: "body_0_2_node", recursively: true)!.removeFromParentNode()
        scene.rootNode.childNode(withName: "body_1_0_node", recursively: true)!.removeFromParentNode()
        scene.rootNode.childNode(withName: "body_1_1_node", recursively: true)!.removeFromParentNode()
    }
    
    func connect() {
        session = MCSession(peer: type(of: self).peerID, securityIdentity: nil, encryptionPreference: .none)
        session?.delegate = self

        browser = MCNearbyServiceBrowser(peer: type(of: self).peerID, serviceType: "MyOpenData")
        browser?.delegate = self
        browser?.startBrowsingForPeers()
    }
    
    // for audio
    var queue: AudioQueueRef!
    var timer: Timer?
    
    func startUpdatingVolume() {
        // Set data format
        var dataFormat = AudioStreamBasicDescription(
            mSampleRate: 44100.0,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: AudioFormatFlags(kLinearPCMFormatFlagIsBigEndian | kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked),
            mBytesPerPacket: 2,
            mFramesPerPacket: 1,
            mBytesPerFrame: 2,
            mChannelsPerFrame: 1,
            mBitsPerChannel: 16,
            mReserved: 0)
        
        // Observe input level
        var audioQueue: AudioQueueRef? = nil
        var error = noErr
        error = AudioQueueNewInput(
            &dataFormat,
            audioQueueInputCallback,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            .none,
            .none,
            0,
            &audioQueue)
        if error == noErr {
            self.queue = audioQueue
        }
        AudioQueueStart(self.queue, nil)
        
        // Enable level meter
        var enabledLevelMeter: UInt32 = 1
        AudioQueueSetProperty(self.queue, kAudioQueueProperty_EnableLevelMetering, &enabledLevelMeter, UInt32(MemoryLayout<UInt32>.size))
        
        self.timer = Timer.scheduledTimer(timeInterval: 0.3,
                                          target: self,
                                          selector: #selector(SceneViewController.detectVolume(_:)),
                                          userInfo: nil,
                                          repeats: true)
        //self.timer?.fire()
    }
    
    @objc func detectVolume(_ timer: Timer)
    {
        // Get level
        var levelMeter = AudioQueueLevelMeterState()
        var propertySize = UInt32(MemoryLayout<AudioQueueLevelMeterState>.size)
        
        AudioQueueGetProperty(
            self.queue,
            kAudioQueueProperty_CurrentLevelMeterDB,
            &levelMeter,
            &propertySize)
        print(levelMeter)
        
        let node = scene.rootNode.childNode(withName: "face_2_0_node", recursively: true)!
        if (levelMeter.mPeakPower > -20) {
            let rand = [1,3,4][Int(arc4random()%3)]
            let mouthN = Bundle.main.url(forResource: "art.scnassets/link/Textures/mouth.\(rand)", withExtension: "png")!
            node.geometry?.firstMaterial?.diffuse.contents = NSImage(contentsOf: mouthN)
        } else {
            let mouth0 = Bundle.main.url(forResource: "art.scnassets/link/Textures/mouth.0", withExtension: "png")!
            node.geometry?.firstMaterial?.diffuse.contents = NSImage(contentsOf: mouth0)
        }
    }
}

extension SceneViewController: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("##### \(#function) \(#line) \(#column)")
        print("\(peerID)")
        browser.invitePeer(peerID, to: session!, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("##### \(#function) \(#line) \(#column)")
        print("\(peerID)")
    }
}

extension SceneViewController: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("##### \(#function) \(#line) \(#column)")
        print("\(peerID) : \(state.rawValue)")
    }
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let d = NSKeyedUnarchiver.unarchiveObject(with: data) as! [String: Double]
        
        if baseYaw == nil {
            baseYaw = d["yaw"]
        }
        
        let headNode = scene.rootNode.childNode(withName: "head_jnt", recursively: true)!
        // yaw(223) 0-360 / roll(-5) +-90 / pitch(15) +-180
        // Y / Z / X
        
        let dx = SCNMatrix4MakeRotation(CGFloat(-(15-d["pitch"]!)/180) * CGFloat.pi, 0, 0, 1)
        let dy = SCNMatrix4MakeRotation(CGFloat((baseYaw!-d["yaw"]!)/180) * CGFloat.pi, 1, 0, 0)
        let dz = SCNMatrix4MakeRotation(CGFloat((-5-d["roll"]!)/180) * CGFloat.pi, 0, 1, 0)
        DispatchQueue.main.async {
            headNode.transform = SCNMatrix4Mult(SCNMatrix4Mult(dx, dy), dz)
        }

        if (d["blinkSpeed"]! > 0) {
            let node = scene.rootNode.childNode(withName: "face_3_0_node", recursively: true)!
            let eye3 = Bundle.main.url(forResource: "art.scnassets/link/Textures/eye.3", withExtension: "png")!
            node.geometry?.firstMaterial?.diffuse.contents = NSImage(contentsOf: eye3)
            let timer = Timer(timeInterval: 0.2, repeats: false) { _ in
                let eye0 = Bundle.main.url(forResource: "art.scnassets/link/Textures/eye.0", withExtension: "png")!
                node.geometry?.firstMaterial?.diffuse.contents = NSImage(contentsOf: eye0)
            }
            RunLoop.main.add(timer, forMode: RunLoopMode.commonModes)
        }
    }
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("\(#file) \(#function) \(#line) \(#column)")
    }
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("\(#file) \(#function) \(#line) \(#column)")
    }
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        print("\(#file) \(#function) \(#line) \(#column)")
    }
}

// for sound
private func audioQueueInputCallback(
    _ inUserData: UnsafeMutableRawPointer?,
    inAQ: AudioQueueRef,
    inBuffer: AudioQueueBufferRef,
    inStartTime: UnsafePointer<AudioTimeStamp>,
    inNumberPacketDescriptions: UInt32,
    inPacketDescs: UnsafePointer<AudioStreamPacketDescription>?)
{
    // Do nothing, because not recoding.
}
