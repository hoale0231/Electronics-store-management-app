import { Modal, Button, Form, Row, Col } from 'react-bootstrap'
import { useState, useEffect } from "react";

export default function OrderDescription(props) {
  const {id_order, id_prod, setPIODescription, deletePIO, action} = props
  const [info, setInfo] = useState({})

  useEffect(() => {
    if (action !== "Edit") {
      return;
    }
    fetch("/api/order/infopio?id_order="+id_order+"&id_prod="+id_prod)
      .then((response) => {
        if (response.ok) {
          return response.json()
        } else {
          response.text().then(text => { alert(text);})
        }
      })
      .then((data) => {setInfo(data)})
      .catch((error) => {
        console.error("Error fetching data: ", error);
      })
  }, [id_order, id_prod, action])

  const [validated, setValidated] = useState(false);

  const handleSubmit = (event) => {
    const form = event.currentTarget;
    if (form.ID_Order.value === "") {
      alert("Import Order ID!")
      event.stopPropagation();
      event.preventDefault();
      return
    }
    if (form.ID_Prod.value === "") {
      alert("Import Product ID!")
      event.stopPropagation();
      event.preventDefault();
      return
    }
    if (form.Quantity.value === "") {
        alert("Import Quantity!")
        event.stopPropagation();
        event.preventDefault();
        return
    }
    setValidated(true);
    if (form.checkValidity() === false) {
      event.preventDefault();
      event.stopPropagation();
    } else {
      var query = action === "Edit" ? "/api/order/updatepio" : "/api/order/addpio"
      const requestOptions = {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(info)
      };
      fetch(query, requestOptions)
        .then(response => {
          if (response.ok) {
            setPIODescription(-1, -1)
          } else {
            response.text().then(text => { alert(text); })
          }
        })
    }
  };

  const handleInputChange = (event) => {
    const target = event.target;
    const value = target.type === 'checkbox' ? target.checked : target.value;
    const name = target.name;
    info[name] = value;
  }

  return (
    <div className="popup-background">
      <Modal.Dialog className="popup" size="lg">
        <Modal.Header closeButton onClick={() => setPIODescription(-1, -1)}>
          <Modal.Title>{action}</Modal.Title>
        </Modal.Header>

        <Modal.Body className="body-popup">
          <Form noValidate validated={validated} onSubmit={handleSubmit}>
            <Row className="mb-3">
              <InputGroupCustom info={info} handleInputChange={handleInputChange} attr="ID_Order" attrName="Order ID" required={true} md="4" disable={action === 'Edit'}/>
              <InputGroupCustom info={info} handleInputChange={handleInputChange} attr="ID_Prod" attrName="Product ID" required={true} md="4" disable={action === 'Edit'}/>
            </Row>
            <Row className="mb-3">
              <InputGroupCustom info={info} handleInputChange={handleInputChange} attr="Price" attrName="Price" required={true} md="4" disable={true}/>
              <InputGroupCustom info={info} handleInputChange={handleInputChange} attr="Quantity" attrName="Quantity" required={true} md="4"/>
            </Row>
            <Modal.Footer>
              <Button type="submit">Save Changes</Button>
              {action === "Edit" ? <Button variant="danger" onClick={() => {deletePIO(id_order, id_prod)}}>Delete Order</Button> : <p/>}
            </Modal.Footer>
          </Form>
        </Modal.Body>
      </Modal.Dialog>
    </div>
  )
}


function InputGroupCustom(props) {
  const { info, attr, attrName, required, handleInputChange, md, disable } = props
  return (
    <Form.Group as={Col} md={md}>
      <Form.Label>{attrName}</Form.Label>
      <Form.Control
        required={required}
        disabled={disable}
        name={attr}
        type="text"
        defaultValue={info[attr]}
        onChange={handleInputChange}
      />
      <Form.Control.Feedback type="invalid">
        Invalid {attr}
      </Form.Control.Feedback>
    </Form.Group>
  )
}