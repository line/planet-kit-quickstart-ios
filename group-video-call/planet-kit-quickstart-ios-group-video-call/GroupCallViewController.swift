// Copyright 2025 LINE Plus Corporation
//
// LINE Plus Corporation licenses this file to you under the Apache License,
// version 2.0 (the "License"); you may not use this file except in compliance
// with the License. You may obtain a copy of the License at:
//
//   https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.

import UIKit
import PlanetKit

class GroupCallViewController: UIViewController {
    
    var conference: PlanetKitConference!
    private var peerControl: PlanetKitPeerControl?
    
    private var peerVideoView: PlanetKitMTKView = {
        let videoView = PlanetKitMTKView(frame: .zero, device: nil)
        videoView.layer.borderColor = UIColor.gray.cgColor
        videoView.layer.borderWidth = 1
        videoView.translatesAutoresizingMaskIntoConstraints = false
        videoView.contentMode = .scaleAspectFill
        videoView.clear()
        return videoView
    }()
    
    private var myVideoView: PlanetKitMTKView = {
        let videoView = PlanetKitMTKView(frame: .zero, device: nil)
        videoView.layer.borderColor = UIColor.gray.cgColor
        videoView.layer.borderWidth = 1
        videoView.translatesAutoresizingMaskIntoConstraints = false
        videoView.contentMode = .scaleAspectFill
        videoView.clear()
        return videoView
    }()
    
    private let tableView = UITableView()
    
    private let leaveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Leave", for: .normal)
        button.backgroundColor = UIColor.red
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var peerList = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        
        PlanetKitCameraManager.shared.startPreview(delegate: myVideoView)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        PlanetKitCameraManager.shared.stopPreview(delegate: myVideoView)
    }
    
    private func setupViews() {
        view.backgroundColor = .white
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(PeerCell.self, forCellReuseIdentifier: PeerCell.identifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        leaveButton.addTarget(self, action: #selector(leaveButtonTapped), for: .touchUpInside)
        
        // Add subviews
        [peerVideoView, myVideoView, tableView, leaveButton].forEach {
            view.addSubview($0)
        }
        
        // Constraints for tableView and leaveButton (right side)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.widthAnchor.constraint(equalToConstant: 200),
            tableView.bottomAnchor.constraint(equalTo: leaveButton.topAnchor, constant: -8),
            
            leaveButton.leadingAnchor.constraint(equalTo: tableView.leadingAnchor, constant: 8),
            leaveButton.trailingAnchor.constraint(equalTo: tableView.trailingAnchor, constant: -8),
            leaveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            leaveButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Layout for the left side video views:
        NSLayoutConstraint.activate([
            // Peer video view at the top of the left area
            peerVideoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            peerVideoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            peerVideoView.trailingAnchor.constraint(equalTo: tableView.leadingAnchor),
            
            // My video view at the bottom of the left area
            myVideoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            myVideoView.trailingAnchor.constraint(equalTo: tableView.leadingAnchor),
            myVideoView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // Vertical stacking: myVideoView starts where peerVideoView ends
            myVideoView.topAnchor.constraint(equalTo: peerVideoView.bottomAnchor),
            
            // Both video views have equal height
            peerVideoView.heightAnchor.constraint(equalTo: myVideoView.heightAnchor)
        ])
    }
    
    @objc private func leaveButtonTapped() {
        conference.leaveConference()
    }
    
    private var selectedPeerId: String? {
        let indexPath = tableView.indexPathForSelectedRow
        guard let indexPath = indexPath, indexPath.row < peerList.count else {
            return nil
        }
        return peerList[indexPath.row]
    }
    
    private func showDisconnectedAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
    
    private func showPeerVideo(_ peerId: String) {
        guard let peer = conference.getPeer(peerId: PlanetKitUserId(id: peerId, serviceId: serviceId)) else {
            print("Failed to get peer of \(peerId)")
            return
        }
        guard let peerControl = conference.createPeerControl(peer: peer) else {
            print("Failed to create peer control \(peerId)")
            return
        }
        
        self.peerControl = peerControl
        
        peerControl.register(self) { success in
            guard success else {
                print("Failed to register peer control \(peerId)")
                return
            }
            
            peerControl.startVideo(maxResolution: .recommended, delegate: self.peerVideoView) { success in
                if !success {
                    print("Failed to start peer video \(peerId)")
                }
            }
        }
    }
    
    private func clearPeerVideo() {
        if let oldPeerControl = peerControl {
            oldPeerControl.unregister() { success in
                if !success {
                    print("Failed to unregister peer control")
                }
            }
            peerControl = nil
        }
        peerVideoView.clear()
    }
    
    private func updatePeerList(added: [String], removed: [String]) {
        var updatedPeerList = peerList
        updatedPeerList.append(contentsOf: added)
        updatedPeerList.removeAll(where: { removed.contains($0) })
        
        peerList = updatedPeerList
    }
}

// MARK: - PlanetKitConferenceDelegate
extension GroupCallViewController: PlanetKitConferenceDelegate {
    func didConnect(_ conference: PlanetKitConference, connected param: PlanetKitConferenceConnectedParam) { }
    
    func didDisconnect(_ conference: PlanetKitConference, disconnected param: PlanetKitDisconnectedParam) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }            
            self.showDisconnectedAlert("Disconnected", message: "reason: \(param.reason), source: \(param.source)")
        }
    }
    
    func peerListDidUpdate(_ conference: PlanetKitConference, updated: PlanetKitConferencePeerListUpdateParam) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let addedPeerIdList = updated.addedPeers.map { $0.id.id }
            let removedPeerIdList = updated.removedPeers.map { $0.id.id }
            
            self.updatePeerList(added: addedPeerIdList, removed: removedPeerIdList)
            self.tableView.reloadData()
        }
    }
    
    func peersVideoDidUpdate(_ conference: PlanetKitConference, updated: PlanetKitConferenceVideoUpdateParam) { }
}

// MARK: - PlanetKitPeerControlDelegate
extension GroupCallViewController: PlanetKitPeerControlDelegate {
    func didDisconnect(_ peerControl: PlanetKitPeerControl) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if self.peerControl === peerControl {
                peerControl.unregister() { success in
                    if !success {
                        print("Failed to unregister peer control")
                    }
                }
                clearPeerVideo()
                self.peerControl = nil
            }
        }
    }
    
    func didUpdateVideo(_ peerControl: PlanetKitPeerControl, subgroup: PlanetKitSubgroup, status: PlanetKitVideoStatus) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if status.state == .enabled {
                peerControl.startVideo(maxResolution: .recommended, delegate: self.peerVideoView) { success in
                    if !success {
                        print("Failed to start peer video \(peerControl.peer.id)")
                    }
                }
            } else {
                peerControl.stopVideo { success in
                    if !success {
                        print("Failed to stop peer video \(peerControl.peer.id)")
                    }
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension GroupCallViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peerList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PeerCell.identifier, for: indexPath) as! PeerCell
        cell.configure(with: peerList[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate
extension GroupCallViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        clearPeerVideo()
        guard let peerId = selectedPeerId else {
            return
        }
        showPeerVideo(peerId)
    }
}

// MARK: - PeerCell
extension GroupCallViewController {
    class PeerCell: UITableViewCell {
        static let identifier = "PeerCell"
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            setup()
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setup()
        }
        
        private func setup() {
            selectionStyle = .default
        }
        
        func configure(with peerTitle: String) {
            textLabel?.text = peerTitle
        }
    }
} 
