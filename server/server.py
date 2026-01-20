import socket
import sqlite3

HOST = "0.0.0.0"
PORT = 65432

# ---------- DATABASE SETUP ----------
conn = sqlite3.connect("attendance.db", check_same_thread=False)
cursor = conn.cursor()

cursor.execute("""
    CREATE TABLE IF NOT EXISTS attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_name TEXT NOT NULL,
        status TEXT NOT NULL
    )
""")
conn.commit()
print("Database ready.")

# ---------- SERVER SETUP ----------
server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.bind((HOST, PORT))
server.listen()

print(f"Server listening on {HOST}:{PORT}")

try:
    while True:
        # Accept connection
        client, addr = server.accept()
        print(f"Connection from {addr}")

        try:
            # Receive data
            data = client.recv(1024).decode("utf-8").strip()
            print(f"Received: {data}")

            if data.startswith("ADD:"):
                name = data.replace("ADD:", "").strip()
                if name:
                    # Save to DB
                    cursor.execute(
                        "INSERT INTO attendance (student_name, status) VALUES (?, ?)",
                        (name, "Present")
                    )
                    conn.commit()
                    print(f"Saved {name} to DB")
                    
                    # Send Success Response
                    client.sendall(f"SUCCESS: {name} Marked Present".encode("utf-8"))
                else:
                    client.sendall("ERROR: Name is empty".encode("utf-8"))
            else:
                client.sendall("ERROR: Invalid Format".encode("utf-8"))

        except Exception as e:
            print(f"Error handling client: {e}")
            client.sendall("ERROR: Server Error".encode("utf-8"))
        
        finally:
            # Close connection to allow next student
            client.close()

except KeyboardInterrupt:
    print("\nServer stopping...")
    server.close()
    conn.close()
