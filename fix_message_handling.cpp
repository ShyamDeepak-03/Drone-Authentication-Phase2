// Replace the handleMessageWhenUp and handleIncomingMessage methods

void DroneAuthApp::handleMessageWhenUp(cMessage *msg) {
    if (msg->isSelfMessage()) {
        handleSelfMessage(msg);
    } else if (dynamic_cast<Packet *>(msg)) {
        handleIncomingMessage(msg);
    } else {
        // Handle socket indications (errors, etc.)
        EV_WARN << "Received non-packet message: " << msg->getName() << endl;
        delete msg;
    }
}

void DroneAuthApp::handleIncomingMessage(cMessage *msg) {
    Packet *packet = check_and_cast<Packet *>(msg);
    
    auto chunk = packet->peekDataAsBytes();
    std::vector<uint8_t> data(chunk->getBytes().begin(), chunk->getBytes().end());
    
    // Parse message type (first byte)
    if (data.size() < 1) {
        delete packet;
        return;
    }
    
    uint8_t msgType = data[0];
    
    switch (msgType) {
        case 0x02: // CHALLENGE message
            handleChallengeMessage(data);
            break;
            
        case 0x04: // AUTH_SUCCESS message
            handleAuthSuccessMessage(data);
            break;
            
        case 0x05: // AUTH_FAILURE message
            handleAuthFailureMessage(data);
            break;
            
        default:
            EV_WARN << "Unknown message type: " << (int)msgType << endl;
    }
    
    delete packet;
}
