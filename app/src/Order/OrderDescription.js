import { Modal, Button, Form, Row, Col } from 'react-bootstrap'
import { useState, useEffect } from "react";
import "./OrderDescription.css"

var number = /^-?\d+$/;

export default function OrderDescription(props) {
  const { id, setOrderDescription, deleteOrder, action } = props
  const [info, setInfo] = useState({})

  useEffect(() => {
    if (action !== "Edit") {
      return;
    }
    fetch("/api/order/info?id=" + id)
      .then((response) => {
        if (response.ok) {
          return response.json()
        }
        throw response
      })
      .then((data) => { console.log(data); setInfo(data) })
      .catch((error) => {
        console.error("Error fetching data: ", error);
      })
  }, [id, action])

  const [validated, setValidated] = useState(false);

  const handleSubmit = (event) => {
    const form = event.currentTarget;
    if (!number.test(form.Salary.value)) {
      alert("Import salary much be number!")
      event.stopPropagation();
      event.preventDefault();
      return
    }
    setValidated(true);
    if (form.checkValidity() === false) {
      event.preventDefault();
      event.stopPropagation();
    } else {
      var query = action === "Edit" ? "/api/order/update" : "/api/order/add"
      const requestOptions = {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(info)
      };
      fetch(query, requestOptions)
        .then(response => {
          if (response.ok) {
            setOrderDescription(-1)
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
    // if (name === "ProdType") setProdType(value)
  }


  return (
    <div className="popup-background">
      <Modal.Dialog className="popup" size="lg">
        <Modal.Header closeButton onClick={() => setOrderDescription(-1)}>
          <Modal.Title>{action}</Modal.Title>
        </Modal.Header>

        <Modal.Body className="body-popup">
          <Form noValidate validated={validated} onSubmit={handleSubmit}>
            <Row className="mb-3">
              <InputGroupCustom info={info} handleInputChange={handleInputChange} attr="ID" attrName="ID" required={true} md="4" disable={action === 'Edit'}/>
              <InputGroupCustom info={info} handleInputChange={handleInputChange} attr="TimeCreated" attrName="Time Created" required={true} md="4" disable={action === 'Edit'}/>
              <InputGroupCustom info={info} handleInputChange={handleInputChange} attr="SumPrices" attrName="Sum Prices" required={true} md="4"/>
            </Row>
            <Row className="mb-3">
              <InputGroupCustom info={info} handleInputChange={handleInputChange} attr="ID_Customer" attrName="Customer ID" required={true} md="4"/>
              <InputGroupCustom info={info} handleInputChange={handleInputChange} attr="ID_Employee" attrName="Employee ID" required={true} md="4"/>
              <InputGroupCustom info={info} handleInputChange={handleInputChange} attr="ID_Ad" attrName="CTKM ID" required={true} md="4"/>
            </Row>
            <Modal.Footer>
              <Button type="submit">Save Changes</Button>
              <Button variant="danger" onClick={() => { deleteOrder(id); }}>Delete Order</Button>
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