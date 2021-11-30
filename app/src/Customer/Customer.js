import BootstrapTable from "react-bootstrap-table-next";
import { Button, Form, Row, Col, FloatingLabel } from 'react-bootstrap'
import { useState, useEffect } from "react";
import filterFactory, { textFilter } from 'react-bootstrap-table2-filter';
import CustomerDescription from "./CustomerDescription";

var sortby = "ID"
var orderbyAsc = 1
var minRecommendee = 0

export default function Customer() {
    const [customerDescription, setCustomerDescription] = useState(-1)
    const [customers, setCustomers] = useState([]);

    const columns = [
        { dataField: "ID", text: "Customer ID", filter: textFilter() },
        { dataField: "Username", text: "Username", filter: textFilter() },
        { dataField: "Phone", text: "Phone number", filter: textFilter() },
        { dataField: "Fname", text: "First name", filter: textFilter() },
        { dataField: "Lname", text: "Last name", filter: textFilter() },
        { dataField: "Email", text: "Email", filter: textFilter() },
        { dataField: "Bdate", text: "Birthdate", filter: textFilter() },
        { dataField: "IdNum", text: "ID number", filter: textFilter() },
        { dataField: "FamScore", text: "Familiarity point", filter: textFilter() },
        { dataField: "Num_ref", text: "No. Recommendee", filter: textFilter() },
    ]

    const rowEvents = {
        onClick: (e, row, rowIndex) => {
          setCustomerDescription(row.ID)
        },
    };

    function getCustomers() {
        fetch("/get/customers?sortby=" + sortby + "&asc=" + orderbyAsc + "&minRec=" + minRecommendee)
            .then((response) => {
                if (response.ok) {
                return response.json()
                }
                throw response
            })
            .then((data) => { setCustomers(data); })
            .catch((error) => {
                console.error("Error fetching data: ", error);
            })
    }

    function handleChangeSortBy(event) {
        sortby = event.target.value;
        getCustomers();
    }
    
    function handleChangeSort(event) {
        orderbyAsc = event.target.value;
        getCustomers();
    }

    function isInt(value) {
        return !isNaN(value) && 
               parseInt(Number(value)) == value && 
               !isNaN(parseInt(value, 10));
    }

    function handleChangeText(event) {
        if (isInt(event.target.value)) {
            minRecommendee = Number(event.target.value);
            getCustomers();
        }
    }

    useEffect(() => {
        getCustomers()
    }, [])

    return (
        <div className="popup_container">
            <Button className="customButton" variant="success" onClick={() => { setCustomerDescription(-2) }}>Add staff</Button>
            <div>
                <Row className="g-2">
                <Col md>
                    <FloatingLabel label="Sort by">
                    <Form.Select onChange={handleChangeSortBy}>
                    {/* <Form.Select> */}
                        <option value="ID">Customer ID</option>
                        <option value="Username">Username</option>
                        <option value="Phone">Phone number</option>
                        <option value="Fname">First name</option>
                        <option value="Lname">Last name</option>
                        <option value="Email">Email</option>
                        <option value="Bdate">Birthdate</option>
                        <option value="IdNum">ID number</option>
                        <option value="FamScore">Familiarity point</option>
                    </Form.Select>
                    </FloatingLabel>
                </Col>
                <Col md>
                    <FloatingLabel label="Sort">
                    <Form.Select onChange={handleChangeSort}>
                    {/* <Form.Select> */}
                        <option value="1">Ascending</option>
                        <option value="0">Descending</option>
                    </Form.Select>
                    </FloatingLabel>
                </Col>
                <Col md>
                <FloatingLabel label="Minimum no. recommendee">
                    <Form.Control as="textarea" rows={1} onChange={handleChangeText} defaultValue="0"/>
                </FloatingLabel>
                </Col>
                </Row>
            </div>
            {/* <Button className="customButton" variant="success" onClick={() => { setstaffDescription(0) }}>Add Customer</Button> */}
            <div className="table-custom">
                {/* https://react-bootstrap-table.github.io/react-bootstrap-table2/docs/about.html  */}
                <BootstrapTable keyField="id" data={customers} columns={columns} rowEvents={rowEvents} filter={filterFactory()}/>
            </div>
            <div>
                {customerDescription === -1 ? <p /> : customerDescription === -2 ?
                <CustomerDescription id={customerDescription} setCustomerDescription={setCustomerDescription} action={'Add'} /> :
                <CustomerDescription id={customerDescription} setCustomerDescription={setCustomerDescription} action={'Edit'} />}
            </div>
        </div>
    );
  }