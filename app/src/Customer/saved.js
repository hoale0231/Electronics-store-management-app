import { Modal, Button, Form, Row, Col } from 'react-bootstrap'
import BootstrapTable from "react-bootstrap-table-next";
import { useState, useEffect } from "react";
import "./CustomerDescription.css"

export default function CustomerDescription(props) {
    const { id, setCustomerDescription, action } = props
    const [info, setInfo] = useState({})
    const columns = [
        { dataField: "ID", text: "Customer ID"},
        { dataField: "Username", text: "Username"},
        { dataField: "Phone", text: "Phone number"},
        { dataField: "Fname", text: "First name"},
        { dataField: "Lname", text: "Last name"},
        { dataField: "Email", text: "Email"},
        { dataField: "Bdate", text: "Birthdate"},
        { dataField: "IdNum", text: "ID number"},
        { dataField: "FamScore", text: "Familiarity point"},
    ]

    useEffect(() => {
        if (action !== "Edit") {
          return;
        }
        fetch("/get/customer?id=" + id)
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

    const handleInputChange = (event) => {
        const target = event.target;
        const value = target.type === 'checkbox' ? target.checked : target.value;
        const name = target.name;
        info[name] = value;
    }

    function isInt(value) {
        return !isNaN(value) && 
               parseInt(Number(value)) == value && 
               !isNaN(parseInt(value, 10));
    }

    const [validated, setValidated] = useState(false);
    
    const handleSubmit = (event) => {
        const form = event.currentTarget;
        if (!isInt(form.FamScore.value)) {
          alert("Familiarity point much be number!")
          event.stopPropagation();
          event.preventDefault();
          return
        }
        setValidated(true);
        if (form.checkValidity() === false) {
          event.preventDefault();
          event.stopPropagation();
        } else {
          var query = action === "Edit" ? "/edit/customer" : "/add/customer"
          const requestOptions = {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(info)
          };
          fetch(query, requestOptions)
            .then(response => {
              if (response.ok) {
                setCustomerDescription(-1)
              } else {
                response.text().then(text => { alert(text); })
              }
            })
        }
    };

    return (
        <div className="popup-background">
        <Modal.Dialog className="popup modal-dialog-scrollable" size="lg">
            <Modal.Header closeButton onClick={() => setCustomerDescription(-1)}>
                <Modal.Title>{action}</Modal.Title>
            </Modal.Header>
            <Modal.Body className="body-popup">
                <Form noValidate validated={validated} onSubmit={handleSubmit}>
                <Row className="mb-3">
                    <InputGroupCustom info={info} handleInputChange={handleInputChange} attr="ID" attrName="Customer ID" required={true} md="4" disable={action === 'Edit'} />
                    <InputGroupCustom info={info} handleInputChange={handleInputChange} attr="Username" attrName="Username" required={true} md="4" disable={action === 'Edit'} />
                    <InputGroupCustom info={info} handleInputChange={handleInputChange} attr="Passwd" attrName="Password" required={true} md="4" />
                </Row>
                <Row className="mb-3">
                    <InputGroupCustom info={info} handleInputChange={handleInputChange} attr="Phone" attrName="Phone number" required={true} md="4" />
                    <InputGroupCustom info={info} handleInputChange={handleInputChange} attr="Fname" attrName="First name" md="4" required={true} />
                    <InputGroupCustom info={info} handleInputChange={handleInputChange} attr="Lname" attrName="Last name" md="4" required={true} />
                </Row>
                <Row className="mb-3">
                    <InputGroupCustom info={info} handleInputChange={handleInputChange} attr="Email" attrName="Email" md="4" disable={action === 'Edit'} />
                    <InputGroupCustom info={info} handleInputChange={handleInputChange} attr="Bdate" attrName="Birthdate" md="4" required={true} />
                    <InputGroupCustom info={info} handleInputChange={handleInputChange} attr="IdNum" attrName="ID number" required={true} md="4" />
                </Row>
                <Row className="mb-3">
                    <InputGroupCustom info={info} handleInputChange={handleInputChange} attr="FamScore" attrName="Familiarity point" md="6" required={true} />
                    {action === 'Edit' ? 
                    <InputGroupCustom info={info} handleInputChange={handleInputChange} attr="Num_ref" attrName="Number of Recommendees" md="6" required={true} disable={true}/> :
                    <p/>}
                </Row>
                <Form.Group as={Col} md="12">
                    <Form.Label>List of recommendees:</Form.Label>
                    <table class="table table-striped">
                        <thead>
                            <tr>
                            {columns.map((item, i) => (
                                <th name={item.dataField}>
                                    {item.text}
                                </th>
                            ))}
                            </tr>
                        </thead>
                        <tbody>
                            
                        </tbody>
                    </table>
                </Form.Group>
                <Modal.Footer>
                    <Button type="submit">Save Changes</Button>
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