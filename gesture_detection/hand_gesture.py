#
# Copyright 2024 MangDang (www.mangdang.net) 
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Description: This script is designed to detect hand gesture using the trained AI model along with mediapipe.
#
# Test Method: Type "gesture" and press enter. Make different hand gestures with ONLY one hand (point up, down, 
#              left, and right with your index finger, gesture to come towards you, gesture to stop with palm
#              facing the camera) to make the pupper look into different directions or move.
#

import pickle
import cv2
import mediapipe as mp
import numpy as np
import sys
import time
import threading

sys.path.append("..")
from api import move_api
from MangDang.LCD.ST7789 import ST7789

labels_dict = {0: 'come', 1: 'stop', 2: 'look up', 3: 'look down', 4: 'look right', 5: 'look left', 6: 'quit'}
gestures_dict = {'come': move_api.move_forward, 'stop': move_api.move_forward, 'look up': move_api.look_up, 
                 'look right': move_api.look_left, 'look left': move_api.look_right, 'look down': move_api.look_down, 'init': move_api.init_movement,}

PREDICTED_GESTURE = ""
TROT_FLAGGED = False
MOVEMENT = False

def get_model():
    model_dict = pickle.load(open('models/hand_gesture_model.p', 'rb'))
    model = model_dict['model']

    return model

def init_hand_gesture():
    disp = ST7789()
    disp.begin()

    cap = cv2.VideoCapture(0)

    # Initialize MediaPipe settings
    mp_hands = mp.solutions.hands
    mp_drawing = mp.solutions.drawing_utils
    mp_drawing_styles = mp.solutions.drawing_styles

    # Setting static_image_mode to False for real-time detection
    hands = mp_hands.Hands(static_image_mode=False, max_num_hands=1, min_detection_confidence=0.5)

    return disp, cap, hands, mp_hands, mp_drawing, mp_drawing_styles

def gesture_to_move_forward(gesture, gestures_dict):
    global TROT_FLAGGED
    # msg_trot_press, msg_trot_release, start_msg, stop_msg = gestures_dict[gesture](state="gesture")
    gestures_dict[gesture]()

    # if PREDICTED_GESTURE == 'come':
    #     if not TROT_FLAGGED:
    #         move_api.send_msgs([msg_trot_press, msg_trot_release])
    #         TROT_FLAGGED = True
    #         time.sleep(0.1)
    #         while PREDICTED_GESTURE == 'come':
    #             move_api.send_msgs([start_msg])
    #             time.sleep(0.15)
    #     else:
    #         while PREDICTED_GESTURE == 'come':
    #             move_api.send_msgs([start_msg])
    #             time.sleep(0.15)

    # else:
    #     if TROT_FLAGGED:
    #         move_api.send_msgs([msg_trot_press, msg_trot_release])
    #         TROT_FLAGGED = False
    #         time.sleep(0.15)
    #     else:
    #         TROT_FLAGGED = False
    #         count = 0
    #         while count < 20:
    #             move_api.send_msgs([stop_msg])
    #             count += 1
    #             time.sleep(0.15)

def gesture_to_look(gesture, gestures_dict):
    global TROT_FLAGGED
    # msg_trot_press, msg_trot_release, start_msg, stop_msg = gestures_dict[gesture](state="gesture")
    gestures_dict[gesture]()

    # if TROT_FLAGGED:
    #     move_api.send_msgs([msg_trot_press, msg_trot_release])
    #     TROT_FLAGGED = False
    #     time.sleep(0.1)
    # else:
    #     while gesture == PREDICTED_GESTURE:
    #         _, __, start_msg, stop_msg = gestures_dict[gesture](state="gesture")
    #         move_api.send_msgs([start_msg])
    #         time.sleep(0.1)
    #     count = 0
    #     while count < 20:
    #         move_api.send_msgs([stop_msg])
    #         count += 1
    #         time.sleep(0.1)

def get_gesture(cap, disp, hands, mp_hands, mp_drawing, mp_drawing_styles, model):
    global PREDICTED_GESTURE, MOVEMENT
    
    data_aux = []
    x_ = []
    y_ = []
    
    ret, frame = cap.read()

    # Reduce frame size for faster processing
    frame = cv2.resize(frame, (320, 240))

    # Flip the frame
    frame = cv2.flip(frame, 1)
    
    H, W, _ = frame.shape
    frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

    results = hands.process(frame_rgb)
    frame = cv2.cvtColor(frame, cv2.COLOR_RGB2BGR)

    if results.multi_hand_landmarks:
        for hand_landmarks in results.multi_hand_landmarks:
            mp_drawing.draw_landmarks(
                frame, 
                hand_landmarks, 
                mp_hands.HAND_CONNECTIONS, 
                mp_drawing_styles.get_default_hand_landmarks_style(),
                mp_drawing_styles.get_default_hand_connections_style())

        for hand_landmarks in results.multi_hand_landmarks:
            for i in range(len(hand_landmarks.landmark)):
                x = hand_landmarks.landmark[i].x
                y = hand_landmarks.landmark[i].y

                x_.append(x)
                y_.append(y)

            for i in range(len(hand_landmarks.landmark)):
                x = hand_landmarks.landmark[i].x
                y = hand_landmarks.landmark[i].y
                data_aux.append(x - min(x_))
                data_aux.append(y - min(y_))

        x1 = int(min(x_) * W) - 10
        y1 = int(min(y_) * H) - 10
        x2 = int(max(x_) * W) - 10
        y2 = int(max(y_) * H) - 10

        prediction = model.predict([np.asarray(data_aux)])
        PREDICTED_GESTURE = labels_dict[int(prediction[0])]

        cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 0, 0), 2)
        cv2.putText(frame, PREDICTED_GESTURE, (x1, y1 - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 0, 0), 2, cv2.LINE_AA)

        disp.display(frame)

        print(PREDICTED_GESTURE, MOVEMENT)
        return PREDICTED_GESTURE
    else:
        return ""

def movement_from_gesture(cap, gesture):
    global PREDICTED_GESTURE
    global MOVEMENT
    # if gesture == 'come' or gesture == 'stop':
    #     gesture_thread = threading.Thread(target=gesture_to_move_forward, args=[PREDICTED_GESTURE, gestures_dict])
    #     gesture_thread.start()
    if gesture == 'quit':
        # Release resources
        if (MOVEMENT == True):
            gestures_dict['init']()
            MOVEMENT = False
        cap.release()
        cv2.destroyAllWindows()
    elif gesture == "look up" or gesture == "look down" or gesture == "look left" or gesture == "look right":
        gesture_thread = threading.Thread(target=gesture_to_look, args=[PREDICTED_GESTURE, gestures_dict])
        gesture_thread.start()

def main():
    global MOVEMENT
    model = get_model()
    disp, cap, hands, mp_hands, mp_drawing, mp_drawing_styles = init_hand_gesture()
    while True:
        user_input = input("Enter a command (or 'exit' to quit): ")
        if user_input == "exit":
            break
        elif user_input == "gesture":
            count = 0
            if (MOVEMENT== False):
                gestures_dict['init']()
                MOVEMENT = True
            while True:
                start_time = time.time()
                gesture = get_gesture(cap, disp, hands, mp_hands, mp_drawing, mp_drawing_styles, model)
                if gesture == "":
                    pass
                elif gesture == "quit":
                    count += 1
                    if count == 5:
                        if (MOVEMENT):
                            gestures_dict['init']()
                            MOVEMENT = False
                        cap.release()
                        cv2.destroyAllWindows()
                        cap = cv2.VideoCapture(0)
                        break
                else:
                    movement_from_gesture(cap, gesture)

                # Control frame rate
                elapsed_time = time.time() - start_time
                wait_time = max(1, int((1 / 10 - elapsed_time) * 1000))
                cv2.waitKey(wait_time)

if __name__ == '__main__':
    main()
