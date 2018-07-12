//
//  PeerManager.swift
//  SelfOpenData
//
//  Created by 浅野　宏明 on 2018/06/03.
//  Copyright © 2018年 akylab. All rights reserved.
//

import MultipeerConnectivity

final class PeerManager: NSObject {
    static let shared = PeerManager()
    
    private static let serviceType = "MyOpenData"
    private static let peerID = MCPeerID(displayName: UIDevice.current.name)
    
    private let session: MCSession
    private let advertiser: MCNearbyServiceAdvertiser
    
    private override init() {
        //session = MCSession(peer: type(of: self).peerID)
        session = MCSession(peer: type(of: self).peerID, securityIdentity: nil, encryptionPreference: .none)
        advertiser = MCNearbyServiceAdvertiser(peer: type(of: self).peerID,
                                               discoveryInfo: nil,
                                               serviceType: type(of: self).serviceType)
        
        super.init()
        
        session.delegate = self
        advertiser.delegate = self
    }
    
    func setup() {
        // 常にアドバタイズを行う
        advertiser.startAdvertisingPeer()
    }
    
    func send(data: Data) {
        guard session.connectedPeers.count > 0 else {
            return
        }
        try! session.send(data, toPeers: session.connectedPeers, with: .reliable)
    }
}

extension PeerManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }
}

extension PeerManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("##### \(#function) \(#line) \(#column)")
        print("\(peerID) : \(state.rawValue)")
    }
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("##### \(#function) \(#line) \(#column)")
    }
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("##### \(#function) \(#line) \(#column)")
    }
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("##### \(#function) \(#line) \(#column)")
    }
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        print("##### \(#function) \(#line) \(#column)")
    }
}
