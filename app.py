from flask import Flask, jsonify
import random

app = Flask(__name__)

@app.route('/status')
def get_status():
    statuses = ["Normal", "Caution", "Alert"]
    current_status = random.choice(statuses)
    systems = ["Life Support", "Navigation", "Communication", "Propulsion"]
    system_statuses = {system: random.choice(["OK", "Warning", "Critical"]) for system in systems}
    return jsonify({
        "overall_status": current_status,
        "system_statuses": system_statuses,
        "mission_time": "Day 42, Hour 15"
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
