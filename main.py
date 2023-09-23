from fastapi import FastAPI
from fastapi import Request
from fastapi.responses import JSONResponse
import db_helper
import generic_helper

app = FastAPI()

inprogress_order = {}


@app.post("/")
async def handle_request(request: Request):  # This is the request that dialogflow is sending
    # Retrieve the JSON data from the request
    payload = await request.json()

    # Extract the necessary information from the payload
    # based on the structure of the WebhookRequest from Dialogflow
    intent = payload['queryResult']['intent']['displayName']
    parameters = payload['queryResult']['parameters']
    output_contexts = payload['queryResult']['outputContexts']
    session_id = generic_helper.extract_session_id(output_contexts[0]["name"])

    intent_handler_dict = {
        'Add Order_Context : Ongoing-Order': add_to_order,
        'Complete Order_Context: Ongoing-Order': complete_order,
        'Track Order_Context : Ongoing-Order': track_order
    }

    return intent_handler_dict[intent](parameters, session_id)


def add_to_order(parameters: dict, session_id: str):
    food_items = parameters["Food-Items"]
    quantities = parameters["number"]

    if len(food_items) != len(quantities):
        fulfillment_text = "Sorry, I didn't understand. Please specify food items and quantities correctly."
    else:
        new_food_dict = dict(zip(food_items, quantities))
        if session_id in inprogress_order:
            current_food_dict = inprogress_order[session_id]
            current_food_dict.update(new_food_dict)
            inprogress_order[session_id] = current_food_dict
        else:
            inprogress_order[session_id] = new_food_dict

        # print("****************")
        # print(inprogress_order)

        order_str = generic_helper.get_str_from_food_dict(inprogress_order[session_id])
        fulfillment_text = f"So far you have: {order_str}. Do you need anything else?"

    return JSONResponse(content={
        "fulfillmentText": fulfillment_text
    })


def save_to_db(order: dict):
    next_order_id = db_helper.get_next_order_id()

    # Insert individual items along with quantity in orders table
    for food_item, quantity in order.items():
        rcode = db_helper.insert_order_item(
            food_item,
            quantity,
            next_order_id
        )

        if rcode == -1:
            return -1

    # Now insert order tracking status
    db_helper.insert_order_tracking(next_order_id, "in progress")

    return next_order_id


def complete_order(parameters: dict, session_id: str):
    if session_id not in inprogress_order:
        fulfillment_text = "I'm having a trouble finding your order. Sorry! Can you place a new order please?"
    else:
        order = inprogress_order[session_id]
        order_id = save_to_db(order)
        if order_id == -1:
            fulfillment_text = "Sorry, I couldn't process your order due to a backend error. " \
                               "Please place a new order again"
        else:
            order_total = db_helper.get_total_order_price(order_id)

            fulfillment_text = f"Awesome. We have placed your order. " \
                               f"Here is your order id # {order_id}. " \
                               f"Your order total is {order_total} which you can pay at the time of delivery!"

        del inprogress_order[session_id]

    return JSONResponse(content={
        "fulfillmentText": fulfillment_text
    })


def track_order(parameters: dict, session_id: str):
    order_id = int(parameters["number"])
    order_status = db_helper.get_order_status(order_id)

    if order_status:
        fulfillment_text = f"The order status for order id: {order_id} is: {order_status}"
    else:
        fulfillment_text = f"No order found with order id: {order_id}"

    return JSONResponse(content={
        "fulfillmentText": fulfillment_text
    })
