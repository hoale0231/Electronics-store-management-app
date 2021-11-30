import { Modal, Button, Form, Row, Col } from 'react-bootstrap'
import { useState, useEffect } from "react";
import "./OrderDescription.css"
import BootstrapTable from "react-bootstrap-table-next";

export default function OrderDescription(props) {
  const {id, setOrderDescription, deleteOrder, action} = props
  const [info, setInfo] = useState({})

  useEffect(() => {
    if (action !== "Edit") {
      return;
    }
    fetch("/api/order/info?id=" + id)
      .then((response) => {
        if (response.ok) {
          return response.json()
        } else {
          response.text().then(text => { alert(text);})
        }
      })
      .then((data) => {console.log(data); setInfo(data)})
      .catch((error) => {
        console.error("Error fetching data: ", error);
      })
  }, [id, action])

  const [validated, setValidated] = useState(false);
  const [detail, setDetail] = useState(false);

  const handleSubmit = (event) => {
    const form = event.currentTarget;
    if (form.ID_Customer.value === "") {
      alert("Import Customer ID!")
      event.stopPropagation();
      event.preventDefault();
      return
    }
    if (form.ID_Employee.value === "") {
      alert("Import Employee ID!")
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
  }

  const columns = [
    { dataField: "ID_Order", text: "Order ID"},
    { dataField: "Product_Name", text: "Product Name"},
    { dataField: "Product_Type", text: "Product Type"},
    { dataField: "Device_Type", text: "Device Type"},
    { dataField: "Product_Price", text: "Product Price"},
    { dataField: "Quantity", text: "Quantity"},
  ];
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
              <InputGroupCustom info={info} handleInputChange={handleInputChange} attr="TimeCreated" attrName="Time Created" md="4"/>
              <InputGroupCustom info={info} handleInputChange={handleInputChange} attr="SumPrices" attrName="Sum Prices" md="4"/>
            </Row>
            <Row className="mb-3">
              <InputGroupCustom info={info} handleInputChange={handleInputChange} attr="ID_Customer" attrName="Customer ID" required={true} md="4"/>
              <InputGroupCustom info={info} handleInputChange={handleInputChange} attr="ID_Employee" attrName="Employee ID" required={true} md="4"/>
              <InputGroupCustom info={info} handleInputChange={handleInputChange} attr="ID_Ad" attrName="CTKM ID" md="4"/>
            </Row>
            <BootstrapTable keyField="id" data={info["detail"]} columns={columns}/>
            <Modal.Footer>
              {/* {action === "Edit" ? <Button type="detail" onClick={() => {setDetail(true)}}>Detail</Button> : <p/>} */}
              <Button type="submit">Save Changes</Button>
              {action === "Edit" ? <Button variant="danger" onClick={() => {deleteOrder(id)}}>Delete Order</Button> : <p/>}
            </Modal.Footer>
            {/* <div>
              {detail ? <OrderDetail id={id} setDetail={setDetail}/> : <p/>}
            </div> */}

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