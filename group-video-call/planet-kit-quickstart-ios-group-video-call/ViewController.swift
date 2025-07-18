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

// TODO: Set your own environment
let userId = "<YOUR_USER_ID>"
let serviceId = "planet-kit-quick-start"
let accessToken = "<YOUR_ACCESS_TOKEN>"

class ViewController: UIViewController {

    private let roomIdTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter Room ID"
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let joinButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Join", for: .normal)
        button.backgroundColor = UIColor(red: 0.0, green: 0.478, blue: 1.0, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    var roomId: String {
        roomIdTextField.text ?? ""
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        PlanetKitDeviceHandler.shared.orientation = .portrait
    }
    
    private func setupViews() {
        view.backgroundColor = .white
        view.addSubview(roomIdTextField)
        view.addSubview(joinButton)
        
        joinButton.addTarget(self, action: #selector(joinButtonTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            roomIdTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            roomIdTextField.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            roomIdTextField.widthAnchor.constraint(equalToConstant: 250),
            roomIdTextField.heightAnchor.constraint(equalToConstant: 44),
            
            joinButton.topAnchor.constraint(equalTo: roomIdTextField.bottomAnchor, constant: 20),
            joinButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            joinButton.widthAnchor.constraint(equalToConstant: 250),
            joinButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }
    
    @objc private func joinButtonTapped() {
        let groupCallVC = GroupCallViewController()
        
        let myUserId = PlanetKitUserId(id: userId, serviceId: serviceId)
        let param = PlanetKitConferenceParam(myUserId: myUserId, roomId: roomId, roomServiceId: serviceId, displayName: nil, delegate: groupCallVC, accessToken: accessToken)
        param.mediaType = .audiovideo
        
        let result = PlanetKitManager.shared.joinConference(param: param, settings: nil)
        
        guard result.reason == .none else {
            print("join conference failed. Reason: \(result.reason)")
            return
        }
        groupCallVC.conference = result.conference
        
        present(groupCallVC, animated: true)
    }
}

